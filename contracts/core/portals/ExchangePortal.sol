pragma solidity ^0.4.24;

/*
* This contract do swap for ERC20 via Paraswap, 1inch, and (between synth assest),
  Also Borrow and Reedem via Compound

  Also this contract allow get ratio between crypto curency assets
  Also get ratio for Bancor and Uniswap pools, Syntetix and Compound assets
*/

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";

import "../../paraswap/interfaces/ParaswapInterface.sol";
import "../../paraswap/interfaces/IPriceFeed.sol";
import "../../paraswap/interfaces/IParaswapParams.sol";

import "../../bancor/interfaces/IGetBancorAddressFromRegistry.sol";
import "../../bancor/interfaces/BancorNetworkInterface.sol";
import "../../bancor/interfaces/PathFinderInterface.sol";

import "../../oneInch/IOneSplitAudit.sol";

import "../../compound/CEther.sol";
import "../../compound/CToken.sol";

import "../interfaces/ExchangePortalInterface.sol";
import "../interfaces/PermittedStablesInterface.sol";
import "../interfaces/PoolPortalInterface.sol";
import "../interfaces/ITokensTypeStorage.sol";


contract ExchangePortal is ExchangePortalInterface, Ownable {
  using SafeMath for uint256;

  uint public version = 2;

  // Contract for handle tokens types
  ITokensTypeStorage public tokensTypes;

  // COMPOUND
  CEther public cEther;

  // PARASWAP
  address public paraswap;
  ParaswapInterface public paraswapInterface;
  IPriceFeed public priceFeedInterface;
  IParaswapParams public paraswapParams;
  address public paraswapSpender;

  // 1INCH
  IOneSplitAudit public oneInch;

  // BANCOR
  address public BancorEtherToken;
  IGetBancorAddressFromRegistry public bancorRegistry;

  // CoTrader additional
  PoolPortalInterface public poolPortal;
  PermittedStablesInterface public permitedStable;

  // Enum
  // NOTE: You can add a new type at the end, but do not change this order
  enum ExchangeType { Paraswap, Bancor, OneInch }

  // This contract recognizes ETH by this address
  ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  // Trade event
  event Trade(
     address trader,
     address src,
     uint256 srcAmount,
     address dest,
     uint256 destReceived,
     uint8 exchangeType
  );

  // black list for non trade able tokens
  mapping (address => bool) disabledTokens;

  // Modifier to check that trading this token is not disabled
  modifier tokenEnabled(ERC20 _token) {
    require(!disabledTokens[address(_token)]);
    _;
  }

  /**
  * @dev contructor
  *
  * @param _paraswap               paraswap main address
  * @param _paraswapPrice          paraswap price feed address
  * @param _paraswapParams         helper contract for convert params from bytes32
  * @param _bancorRegistryWrapper  address of Bancor Registry Wrapper
  * @param _BancorEtherToken       address of Bancor ETH wrapper
  * @param _permitedStable         address of permitedStable contract
  * @param _poolPortal             address of pool portal
  * @param _oneInch                address of 1inch OneSplitAudit contract
  * @param _cEther                 address of the COMPOUND cEther
  * @param _tokensTypes            address of the ITokensTypeStorage
  */
  constructor(
    address _paraswap,
    address _paraswapPrice,
    address _paraswapParams,
    address _bancorRegistryWrapper,
    address _BancorEtherToken,
    address _permitedStable,
    address _poolPortal,
    address _oneInch,
    address _cEther,
    address _tokensTypes
    )
    public
  {
    paraswap = _paraswap;
    paraswapInterface = ParaswapInterface(_paraswap);
    priceFeedInterface = IPriceFeed(_paraswapPrice);
    paraswapParams = IParaswapParams(_paraswapParams);
    paraswapSpender = paraswapInterface.getTokenTransferProxy();
    bancorRegistry = IGetBancorAddressFromRegistry(_bancorRegistryWrapper);
    BancorEtherToken = _BancorEtherToken;
    permitedStable = PermittedStablesInterface(_permitedStable);
    poolPortal = PoolPortalInterface(_poolPortal);
    oneInch = IOneSplitAudit(_oneInch);
    cEther = CEther(_cEther);
    tokensTypes = ITokensTypeStorage(_tokensTypes);
  }


  // EXCHANGE Functions

  /**
  * @dev Facilitates a trade for a SmartFund
  *
  * @param _source            ERC20 token to convert from
  * @param _sourceAmount      Amount to convert from (in _source token)
  * @param _destination       ERC20 token to convert to
  * @param _type              The type of exchange to trade with (For now 0 - because only paraswap)
  * @param _additionalArgs    Array of bytes32 additional arguments (For fixed size items and for different types items in array )
  * @param _additionalData    For any size data (if not used set just 0x0)
  *
  * @return The amount of _destination received from the trade
  */
  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
    external
    payable
    tokenEnabled(_destination)
    returns (uint256)
  {

    require(_source != _destination);

    uint256 receivedAmount;

    if (_source == ETH_TOKEN_ADDRESS) {
      require(msg.value == _sourceAmount);
    } else {
      require(msg.value == 0);
    }

    // SHOULD TRADE PARASWAP HERE
    if (_type == uint(ExchangeType.Paraswap)) {
      // call paraswap
      receivedAmount = _tradeViaParaswap(
          _source,
          _destination,
          _sourceAmount,
          _additionalData,
          _additionalArgs
      );
    }
    // SHOULD TRADE BANCOR HERE
    else if (_type == uint(ExchangeType.Bancor)){
      receivedAmount = _tradeViaBancorNewtork(
          _source,
          _destination,
          _sourceAmount
      );
    }
    // SHOULD TRADE 1INCH HERE
    else if (_type == uint(ExchangeType.OneInch)){
      receivedAmount = _tradeViaOneInch(
          _source,
          _destination,
          _sourceAmount
      );
    }

    else {
      // unknown exchange type
      revert();
    }

    require(receivedAmount > 0, "received amount can not be zerro");

    // Send assets
    if (_destination == ETH_TOKEN_ADDRESS) {
      (msg.sender).transfer(receivedAmount);
    } else {
      // transfer tokens received to sender
      _destination.transfer(msg.sender, receivedAmount);
    }

    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = (_source == ETH_TOKEN_ADDRESS) ? address(this).balance : _source.balanceOf(address(this));

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_source == ETH_TOKEN_ADDRESS) {
        (msg.sender).transfer(endAmount);
      } else {
        _source.transfer(msg.sender, endAmount);
      }
    }

    emit Trade(msg.sender, _source, _sourceAmount, _destination, receivedAmount, uint8(_type));

    return receivedAmount;
  }


  // Facilitates trade with Paraswap
  function _tradeViaParaswap(
    address sourceToken,
    address destinationToken,
    uint256 sourceAmount,
    bytes   exchangeData,
    bytes32[] _additionalArgs
 )
   private
   returns (uint256 destinationReceived)
 {
   (uint256 minDestinationAmount,
    address[] memory callees,
    uint256[] memory startIndexes,
    uint256[] memory values,
    uint256 mintPrice) = paraswapParams.getParaswapParamsFromBytes32Array(_additionalArgs);

   if (ERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
     paraswapInterface.swap.value(sourceAmount)(
       sourceToken,
       destinationToken,
       sourceAmount,
       minDestinationAmount,
       callees,
       exchangeData,
       startIndexes,
       values,
       "CoTrader", // referrer
       mintPrice
     );
   } else {
     _transferFromSenderAndApproveTo(ERC20(sourceToken), sourceAmount, paraswapSpender);
     paraswapInterface.swap(
       sourceToken,
       destinationToken,
       sourceAmount,
       minDestinationAmount,
       callees,
       exchangeData,
       startIndexes,
       values,
       "CoTrader", // referrer
       mintPrice
     );
   }

   destinationReceived = tokenBalance(ERC20(destinationToken));
   setTokenType(destinationToken, "CRYPTOCURRENCY");
 }

 // Facilitates trade with 1inch
 function _tradeViaOneInch(
   address sourceToken,
   address destinationToken,
   uint256 sourceAmount
   )
   private
   returns(uint256 destinationReceived)
 {
    (, uint256[] memory distribution) = oneInch.getExpectedReturn(
      IERC20(sourceToken),
      IERC20(destinationToken),
      sourceAmount,
      10,
      0);

    if(ERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
      oneInch.swap.value(sourceAmount)(
        IERC20(sourceToken),
        IERC20(destinationToken),
        sourceAmount,
        1,
        distribution,
        0
        );
    } else {
      _transferFromSenderAndApproveTo(ERC20(sourceToken), sourceAmount, address(oneInch));
      oneInch.swap(
        IERC20(sourceToken),
        IERC20(destinationToken),
        sourceAmount,
        1,
        distribution,
        0
        );
    }

    destinationReceived = tokenBalance(ERC20(destinationToken));
    setTokenType(destinationToken, "CRYPTOCURRENCY");
 }


 // Facilitates trade with Bancor
 function _tradeViaBancorNewtork(
   address sourceToken,
   address destinationToken,
   uint256 sourceAmount
   )
   private
   returns(uint256 returnAmount)
 {
    // get latest bancor contracts
    BancorNetworkInterface bancorNetwork = BancorNetworkInterface(
      bancorRegistry.getBancorContractAddresByName("BancorNetwork")
    );

    PathFinderInterface pathFinder = PathFinderInterface(
      bancorRegistry.getBancorContractAddresByName("BancorNetworkPathFinder")
    );

    // Change source and destination to Bancor ETH wrapper
    address source = ERC20(sourceToken) == ETH_TOKEN_ADDRESS ? BancorEtherToken : sourceToken;
    address destination = ERC20(destinationToken) == ETH_TOKEN_ADDRESS ? BancorEtherToken : destinationToken;

    // Get Bancor tokens path
    address[] memory path = pathFinder.generatePath(source, destination);

    // Convert addresses to ERC20
    ERC20[] memory pathInERC20 = new ERC20[](path.length);
    for(uint i=0; i<path.length; i++){
        pathInERC20[i] = ERC20(path[i]);
    }

    // trade
    if (ERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
      returnAmount = bancorNetwork.convert.value(sourceAmount)(pathInERC20, sourceAmount, 1);
    }
    else {
      _transferFromSenderAndApproveTo(ERC20(sourceToken), sourceAmount, address(bancorNetwork));
      returnAmount = bancorNetwork.claimAndConvert(pathInERC20, sourceAmount, 1);
    }
 }


  /**
  * @dev Transfers tokens to this contract and approves them to another address
  *
  * @param _source          Token to transfer and approve
  * @param _sourceAmount    The amount to transfer and approve (in _source token)
  * @param _to              Address to approve to
  */
  function _transferFromSenderAndApproveTo(ERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, address(this), _sourceAmount));

    _source.approve(_to, _sourceAmount);
  }


  /**
  * @dev buy Compound cTokens
  *
  * @param _amount       amount of ERC20 or ETH
  * @param _cToken       cToken address
  */
  function compoundMint(uint256 _amount, address _cToken)
   external
   payable
   returns(uint256)
  {
    uint256 receivedAmount = 0;
    if(_cToken == address(cEther)){
      // mint cETH
      cEther.mint.value(_amount)();
      // transfer received cETH back to fund
      receivedAmount = cEther.balanceOf(address(this));
      cEther.transfer(msg.sender, receivedAmount);
    }else{
      // mint cERC20
      CToken cToken = CToken(_cToken);
      address underlyingAddress = cToken.underlying();
      _transferFromSenderAndApproveTo(ERC20(underlyingAddress), _amount, address(_cToken));
      cToken.mint(_amount);
      // transfer received cERC back to fund
      receivedAmount = cToken.balanceOf(address(this));
      cToken.transfer(msg.sender, receivedAmount);
    }

    require(receivedAmount > 0, "received amount can not be zerro");

    setTokenType(_cToken, "COMPOUND");
    return receivedAmount;
  }

  /**
  * @dev sell certain percent of Ctokens to Compound
  *
  * @param _percent      percent from 1 to 100
  * @param _cToken       cToken address
  */
  function compoundRedeemByPercent(uint _percent, address _cToken)
   external
   returns(uint256)
  {
    uint256 receivedAmount = 0;

    uint256 amount = getPercentFromCTokenBalance(_percent, _cToken, msg.sender);

    // transfer amount from sender
    ERC20(_cToken).transferFrom(msg.sender, address(this), amount);

    // reedem
    if(_cToken == address(cEther)){
      // redeem compound ETH
      cEther.redeem(amount);
      // transfer received ETH back to fund
      receivedAmount = address(this).balance;
      (msg.sender).transfer(receivedAmount);

    }else{
      // redeem ERC20
      CToken cToken = CToken(_cToken);
      cToken.redeem(amount);
      // transfer received ERC20 back to fund
      address underlyingAddress = cToken.underlying();
      ERC20 underlying = ERC20(underlyingAddress);
      receivedAmount = underlying.balanceOf(address(this));
      underlying.transfer(msg.sender, receivedAmount);
    }

    require(receivedAmount > 0, "received amount can not be zerro");

    return receivedAmount;
  }

  // VIEW Functions

  function tokenBalance(ERC20 _token) private view returns (uint256) {
    if (_token == ETH_TOKEN_ADDRESS)
      return address(this).balance;
    return _token.balanceOf(address(this));
  }

  /**
  * @dev Gets the ratio by amount of token _from in token _to by totekn type
  *
  * @param _from      Address of token we're converting from
  * @param _to        Address of token we're getting the value in
  * @param _amount    The amount of _from
  *
  * @return best price from Paraswap or 1inch for ERC20, or ratio for Uniswap and Bancor pools
  */
  function getValue(address _from, address _to, uint256 _amount) public view returns (uint256){
    if(_amount > 0){
      if(tokensTypes.getType(_from) == bytes32("CRYPTOCURRENCY")){
        uint256 valueFromOneInch = getValueViaOneInch(_from, _to, _amount);
        uint256 valueFromParaswap = getValueViaParaswap(_from, _to, _amount);
        // return best price
        return (valueFromOneInch > valueFromParaswap)
        ? valueFromOneInch
        : valueFromParaswap;
      }
      else if (tokensTypes.getType(_from) == bytes32("BANCOR POOL")){
        return getValueViaBancor(_from, _to, _amount);
      }
      else if (tokensTypes.getType(_from) == bytes32("UNISWAP POOL")){
        return getValueForUniswapPools(_from, _to, _amount);
      }
      else if (tokensTypes.getType(_from) == bytes32("COMPOUND")){
        return getValueViaCompound(_from, _to, _amount);
      }
      else{
        // Unmarked type, try find value
        return findValue(_from, _to, _amount);
      }
    }
    else{
      return 0;
    }
  }

  /**
  * @dev find the ratio by amount of token _from in token _to trying all available methods
  *
  * @param _from      Address of token we're converting from
  * @param _to        Address of token we're getting the value in
  * @param _amount    The amount of _from
  *
  * @return best price from Paraswap or 1inch for ERC20, or ratio for Uniswap and Bancor pools
  */
  function findValue(address _from, address _to, uint256 _amount) public view returns (uint256) {
     if(_amount > 0){
       // If Paraswap return 0, check from 1inch for ensure
       uint256 paraswapResult = getValueViaParaswap(_from, _to, _amount);
       if(paraswapResult > 0)
         return paraswapResult;

       // If 1inch return 0, check from Bancor network for ensure this is not a Bancor pool
       uint256 oneInchResult = getValueViaOneInch(_from, _to, _amount);
       if(oneInchResult > 0)
         return oneInchResult;

       // If Bancor return 0, check from Syntetix network for ensure this is not Synth asset
       uint256 bancorResult = getValueViaBancor(_from, _to, _amount);
       if(bancorResult > 0)
          return bancorResult;

       // If Compound return 0, check from Uniswap pools for ensure this is not Uniswap
       uint256 compoundResult = getValueViaCompound(_from, _to, _amount);
       if(compoundResult > 0)
          return compoundResult;

       // Uniswap pools return 0 if these is not a Uniswap pool
       return getValueForUniswapPools(_from, _to, _amount);
     }
     else{
       return 0;
     }
  }

  // helper for get ratio between assets in Paraswap aggregator
  function getValueViaParaswap(
    address _from,
    address _to,
    uint256 _amount
  ) public view returns (uint256 value) {
    // Check call Paraswap (Because Paraswap can return error for some not supported  assets)
    (bool success) = address(priceFeedInterface).call(
    abi.encodeWithSelector(priceFeedInterface.getBestPriceSimple.selector, _from, _to, _amount));
    // if Paraswap can get rate for this assets, use Paraswap
    if(success){
      value = priceFeedInterface.getBestPriceSimple(_from, _to, _amount);
    }else{
      value = 0;
    }
  }

  // helper for get ratio between assets in 1inch aggregator
  function getValueViaOneInch(
    address _from,
    address _to,
    uint256 _amount
  ) public view returns (uint256 value) {
    // Check call 1inch
    (bool success) = address(oneInch).call(
    abi.encodeWithSelector(oneInch.getExpectedReturn.selector, IERC20(_from), IERC20(_to), _amount));
    // if 1inch can get rate for this assets, use 1inch
    if(success){
      (uint256 returnAmount, ) = oneInch.getExpectedReturn(
        IERC20(_from),
        IERC20(_to),
        _amount,
        10,
        0);
      value = returnAmount;
    }else{
      value = 0;
    }
  }

  // helper for get ratio between assets in Bancor network
  function getValueViaBancor(
    address _from,
    address _to,
    uint256 _amount
  )
  public
  view
  returns (uint256 value)
  {
    // Check call Bancor (Because Bancor can return error for some not supported assets)
    (bool success) = address(poolPortal).call(
    abi.encodeWithSelector(poolPortal.getBancorRatio.selector, _from, _to, _amount));
    // if Bancor can get rate for this assets use Bancor
    if(success){
      value = poolPortal.getBancorRatio(_from, _to, _amount);
    }else{
      value = 0;
    }
  }

  // helper for get value between Compound assets and ETH/ERC20
  // NOTE: _from should be COMPOUND cTokens,
  // amount should be 1e8 because cTokens support 8 decimals
  function getValueViaCompound(
    address _from,
    address _to,
    uint256 _amount
  ) public view returns (uint256 value) {
    // get underlying amount by cToken amount
    uint256 underlyingAmount = getCompoundUnderlyingRatio(
      _from,
      _amount
    );
    // convert underlying in _to
    if(underlyingAmount > 0){
      // get underlying address
      address underlyingAddress = (_from == address(cEther))
      ? ETH_TOKEN_ADDRESS
      : CToken(_from).underlying();
      // get rate for underlying address via paraswap
      return getValueViaParaswap(underlyingAddress, _to, underlyingAmount);
    }
    else{
      return 0;
    }
  }

  // helper for get underlying amount by cToken amount
  // NOTE: _from should be Compound token, amount = input * 1e8 (not 1e18)
  function getCompoundUnderlyingRatio(
    address _from,
    uint256 _amount
  )
    public
    view returns (uint256)
  {
    // Check call
    (bool success) = address(_from).call(
    abi.encodeWithSelector(CToken(_from).exchangeRateCurrent.selector));

    if(success){
      // get underlying amount by cToken amount
      uint256 rate = CToken(_from).exchangeRateCurrent();
      uint256 underlyingAmount = _amount.mul(rate).div(1e18);
      return underlyingAmount;
    }else{
      return 0;
    }
  }

  // helper for get ratio between pools in Uniswap network
  // _from - should be uniswap pool address
  function getValueForUniswapPools(
    address _from,
    address _to,
    uint256 _amount
  )
  public
  view
  returns (uint256)
  {
    // get connectors amount
    (uint256 ethAmount,
     uint256 ercAmount) = poolPortal.getUniswapConnectorsAmountByPoolAmount(
      _amount,
      _from
    );
    // get ERC amount in ETH
    address token = poolPortal.getTokenByUniswapExchange(_from);
    uint256 ercAmountInETH = getValueViaParaswap(token, ETH_TOKEN_ADDRESS, ercAmount);
    // sum ETH with ERC amount in ETH
    uint256 totalETH = ethAmount.add(ercAmountInETH);

    // if _to == ETH no need additional convert, just return ETH amount
    if(_to == address(ETH_TOKEN_ADDRESS)){
      return totalETH;
    }
    // convert ETH into _to asset via Paraswap
    else{
      return getValueViaParaswap(ETH_TOKEN_ADDRESS, _to, totalETH);
    }
  }

  /**
  * @dev return percent of compound cToken balance
  *
  * @param _percent       amount of ERC20 or ETH
  * @param _cToken        cToken address
  * @param _holder        address of cToken holder
  */
  function getPercentFromCTokenBalance(uint _percent, address _cToken, address _holder)
   public
   view
   returns(uint256)
  {
    if(_percent == 100){
      return ERC20(_cToken).balanceOf(_holder);
    }
    else if(_percent > 0 && _percent < 100){
      uint256 currectBalance = ERC20(_cToken).balanceOf(_holder);
      return currectBalance.div(100).mul(_percent);
    }
    else{
      // not correct percent
      return 0;
    }
  }

  function getCTokenUnderlying(address _cToken) public view returns(address){
    return CToken(_cToken).underlying();
  }

  /**
  * @dev get value for cToken in base asset (ERC20 or ETH) ratio for this smart fund address
  *
  * @param _cToken       cToken address
  */
  function compoundGetCTokenValue(
    address _cToken
  )
    public
    view
    returns(uint256 result)
  {
    result = CToken(_cToken).balanceOfUnderlying(address(this));
  }

  /**
  * @dev Gets the total value of array of tokens and amounts
  *
  * @param _fromAddresses    Addresses of all the tokens we're converting from
  * @param _amounts          The amounts of all the tokens
  * @param _to               The token who's value we're converting to
  *
  * @return The total value of _fromAddresses and _amounts in terms of _to
  */
  function getTotalValue(
    address[] calldata _fromAddresses,
    uint256[] calldata _amounts,
    address _to)
    external
    view
    returns (uint256)
  {
    uint256 sum = 0;
    for (uint256 i = 0; i < _fromAddresses.length; i++) {
      sum = sum.add(getValue(_fromAddresses[i], _to, _amounts[i]));
    }
    return sum;
  }

  // SETTERS Functions

  /**
  * @dev Allows the owner to disable/enable the buying of a token
  *
  * @param _token      Token address whos trading permission is to be set
  * @param _enabled    New token permission
  */
  function setToken(address _token, bool _enabled) external onlyOwner {
    disabledTokens[_token] = _enabled;
  }

  // owner can change IFeed
  function setNewIFeed(address _paraswapPrice) external onlyOwner {
    priceFeedInterface = IPriceFeed(_paraswapPrice);
  }

  // owner can change paraswap spender address
  function setNewParaswapSpender(address _paraswapSpender) external onlyOwner {
    paraswapSpender = _paraswapSpender;
  }

  // owner can change paraswap Augustus
  function setNewParaswapMain(address _paraswap) external onlyOwner {
    paraswapInterface = ParaswapInterface(_paraswap);
  }

  // owner can change oneInch
  function setNewOneInch(address _oneInch) external onlyOwner {
    oneInch = IOneSplitAudit(_oneInch);
  }

  // Exchange portal can mark each token
  function setTokenType(address _token, string _type) private {
    // no need add type, if token alredy registred
    if(tokensTypes.isRegistred(_token))
      return;

    tokensTypes.addNewTokenType(_token,  _type);
  }

  // fallback payable function to receive ether from other contract addresses
  function() public payable {}

}

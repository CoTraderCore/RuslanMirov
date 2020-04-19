pragma solidity ^0.4.24;
/**
* This contract convert source ERC20 token to destanation token
* support sources 1INCH, COMPOUND, SYNTHETIX, BANCOR/UNISWAP pools
*/

import "../interfaces/ExchangePortalInterface.sol";
import "../interfaces/PoolPortalInterface.sol";
import "../interfaces/ITokensTypeStorage.sol";
import "../../compound/CToken.sol";
import "../../zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";

contract ConvertPortal {
  address constant private ETH_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  bytes32[] private BYTES32_EMPTY_ARRAY = new bytes32[](0);
  address public CEther;
  address public sUSD;
  ExchangePortalInterface public exchangePortal;
  PoolPortalInterface public poolPortal;
  ITokensTypeStorage  public tokensTypes;

  /**
  * @dev contructor
  *
  * @param _exchangePortal         address of exchange portal
  * @param _poolPortal             address of pool portal
  * @param _tokensTypes            address of the tokens type storage
  * @param _CEther                 address of Compound ETH wrapper
  * @param _sUSD                   address of Synthetix USD wrapper
  */
  constructor(
    address _exchangePortal,
    address _poolPortal,
    address _tokensTypes,
    address _CEther,
    address _sUSD
    )
    public
  {
    exchangePortal = ExchangePortalInterface(_exchangePortal);
    poolPortal = PoolPortalInterface(_poolPortal);
    tokensTypes = ITokensTypeStorage(_tokensTypes);
    CEther = _CEther;
    sUSD = _sUSD;
  }

  // convert CRYPTOCURRENCY, COMPOUND, SYNTHETIX, BANCOR/UNISWAP pools to _destination asset
  function convert(
    address _source,
    uint256 _sourceAmount,
    address _destination,
    address _receiver
  )
    external
    payable
  {
    uint256 receivedAmount = 0;
    // convert assets
    if(tokensTypes.getType(_source) == bytes32("CRYPTOCURRENCY")){
      receivedAmount = convertCryptocurency(_source, _sourceAmount, _destination);
    }
    else if (tokensTypes.getType(_source) == bytes32("BANCOR POOL")){
      receivedAmount = convertBancorPool(_source, _sourceAmount, _destination);
    }
    else if (tokensTypes.getType(_source) == bytes32("UNISWAP POOL")){
      receivedAmount = convertUniswapPool(_source, _sourceAmount, _destination);
    }
    else if (tokensTypes.getType(_source) == bytes32("COMPOUND")){
      receivedAmount = convertCompound(_source, _sourceAmount, _destination);
    }
    else if(tokensTypes.getType(_source) == bytes32("SYNTHETIX")){
      receivedAmount = convertSynthetix(_source, _sourceAmount, _destination);
    }
    else {
      // Unknown type
      revert();
    }

    // send assets to _receiver
    if (_destination == ETH_TOKEN_ADDRESS) {
      (_receiver).transfer(receivedAmount);
    } else {
      // transfer tokens received to sender
      ERC20(_destination).transfer(_receiver, receivedAmount);
    }

    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = (_source == ETH_TOKEN_ADDRESS)
    ? address(this).balance
    : ERC20(_source).balanceOf(address(this));

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_source == ETH_TOKEN_ADDRESS) {
        (_receiver).transfer(endAmount);
      } else {
        ERC20(_source).transfer(_receiver, endAmount);
      }
    }
  }

  // helper for convert Compound asset
  function convertCompound(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {
    // step 1 convert cToken to underlying
    CToken(_source).redeem(_sourceAmount);

    // step 2 get underlying address and received underlying amount
    address underlyingAddress = (_source == CEther)
    ? ETH_TOKEN_ADDRESS
    : CToken(_source).underlying();

    uint256 underlyingAmount = (_source == CEther)
    ? address(this).balance
    : ERC20(_source).balanceOf(address(this));

    // step 3 convert underlying to destination if _destination != underlyingAddress
    if(_destination != underlyingAddress){
      uint256 destAmount = 0;
      // convert via 1inch
      // Convert ETH
      if(underlyingAddress == ETH_TOKEN_ADDRESS){
        destAmount = exchangePortal.trade.value(underlyingAmount)(
          ERC20(underlyingAddress),
          underlyingAmount,
          ERC20(_destination),
          2,
          BYTES32_EMPTY_ARRAY,
          "0x"
        );
      }
      // Convert ERC20
      else{
        ERC20(underlyingAddress).approve(address(exchangePortal), underlyingAmount);
        destAmount = exchangePortal.trade(
          ERC20(underlyingAddress),
          underlyingAmount,
          ERC20(_destination),
          2,
          BYTES32_EMPTY_ARRAY,
          "0x"
        );
      }
      return destAmount;
    }
    else{
      return underlyingAmount;
    }

  }

  // helper for convert Unswap asset
  function convertUniswapPool(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {
    // sell pool
    _transferFromSenderAndApproveTo(ERC20(_source), _sourceAmount, address(poolPortal));

    poolPortal.sellPool(
      _sourceAmount,
      1, // type Uniswap
      ERC20(_source)
    );

    // convert pool connectors to destanation
    // get erc20 connector address
    address ERCConnector = poolPortal.getTokenByUniswapExchange(_source);
    uint256 ERCAmount = ERC20(ERCConnector).balanceOf(address(this));

    // convert ERC20 connector via 1inch
    ERC20(ERCConnector).approve(address(exchangePortal), ERCAmount);
    exchangePortal.trade(
      ERC20(ERCConnector),
      ERCAmount,
      ERC20(_destination),
      2, // type 1inch
      BYTES32_EMPTY_ARRAY,
      "0x"
    );

    // if destanation != ETH, convert ETH also
    if(_destination != ETH_TOKEN_ADDRESS){
      uint256 ETHAmount = address(this).balance;
      exchangePortal.trade.value(ETHAmount)(
        ERC20(ETH_TOKEN_ADDRESS),
        ETHAmount,
        ERC20(_destination),
        2, // type 1inch
        BYTES32_EMPTY_ARRAY,
        "0x"
      );
    }

    // return received amount
    if(_destination == ETH_TOKEN_ADDRESS){
      return address(this).balance;
    }else{
      return ERC20(_destination).balanceOf(address(this));
    }
  }

  // helper for convert Syntetix asset
  // from should be Synthetix asset
  function convertSynthetix(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {
    uint256 destAmount = 0;
    _transferFromSenderAndApproveTo(ERC20(_source), _sourceAmount, address(exchangePortal));
    if(_source == sUSD){
      // if this is sUSD, convert via 1inch
      destAmount = exchangePortal.trade(
        ERC20(_source),
        _sourceAmount,
        ERC20(_destination),
        2,
        BYTES32_EMPTY_ARRAY,
        "0x"
      );
    }
    else{
      // else convert source to cUSD via Syntetix
      uint256 sUSDAmount = exchangePortal.trade(
        ERC20(_source),
        _sourceAmount,
        ERC20(sUSD),
        3, // type Synthetix
        BYTES32_EMPTY_ARRAY,
        "0x"
      );

      // then convert sUSD to destination via 1inch
      ERC20(sUSD).approve(address(exchangePortal), sUSDAmount);
      destAmount = exchangePortal.trade(
        ERC20(sUSD),
        _sourceAmount,
        ERC20(_destination),
        2, // type 1inch
        BYTES32_EMPTY_ARRAY,
        "0x"
      );
    }

    return destAmount;
  }

  // helper for convert standrad crypto assets
  function convertCryptocurency(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {
    _transferFromSenderAndApproveTo(ERC20(_source), _sourceAmount, address(exchangePortal));
    // Convert crypto via 1inch aggregator
    uint256 destAmount = exchangePortal.trade(
      ERC20(_source),
      _sourceAmount,
      ERC20(_destination),
      2,
      BYTES32_EMPTY_ARRAY,
      "0x"
    );

    return destAmount;
  }

  // helper for convert Bancor pools asset
  function convertBancorPool(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {
    _transferFromSenderAndApproveTo(ERC20(_source), _sourceAmount, address(exchangePortal));
    // Convert BNT pools just via Bancor DEX
    uint256 destAmount = exchangePortal.trade(
      ERC20(_source),
      _sourceAmount,
      ERC20(_destination),
      1,
      BYTES32_EMPTY_ARRAY,
      "0x"
    );

    return destAmount;
  }

  /**
  * @dev Transfers tokens to this contract and approves them to another address
  *
  * @param _source          Token to transfer and approve
  * @param _sourceAmount    The amount to transfer and approve (in _source token)
  * @param _to              Address to approve to
  */
  function _transferFromSenderAndApproveTo(ERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, address(this), _sourceAmount), "Can not transfer from");

    _source.approve(_to, _sourceAmount);
  }

  // fallback payable function to receive ether from other contract addresses
  function() public payable {}
}

pragma solidity ^0.4.24;

import "../../../contracts/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../../contracts/core/interfaces/ITokensTypeStorage.sol";

import "../synthetixMock/ISynth.sol";
import "../synthetixMock/ISynthetix.sol";
import "../synthetixMock/IAddressResolver.sol";
import "../synthetixMock/IExchangeRates.sol";

import "../compoundMock/CEther.sol";
import "../compoundMock/CToken.sol";

contract ExchangePortalMock {

  using SafeMath for uint256;
  ITokensTypeStorage public tokensTypes;

  // Synthetix
  ISynthetix public synthetix;
  IAddressResolver public synthetixAddressResolver;

  // This contract recognizes ETH by this address, airswap recognizes ETH as address(0x0)
  ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  address constant private NULL_ADDRESS = address(0);
  // multiplyer and divider are used to set prices. X ether = X*(mul/div) token,
  // similarly X token = X*(div/mul) ether for every token where X is the amount
  uint256 public mul;
  uint256 public div;
  address public stableCoinAddress;
  bool public stopTransfer;

  CEther public cEther;

  // Enum
  enum ExchangeType { Paraswap, Bancor, OneInch, Synthetix}

  event Trade(address trader, address src, uint256 srcAmount, address dest, uint256 destReceived, uint8 exchangeType);

  constructor(
    uint256 _mul,
    uint256 _div,
    address _stableCoinAddress,
    address _synthetix,
    address _synthetixAddressResolver,
    address _cETH,
    address _tokensTypes
    )
    public
  {
    mul = _mul;
    div = _div;
    stableCoinAddress = _stableCoinAddress;
    synthetix = ISynthetix(_synthetix);
    synthetixAddressResolver = IAddressResolver(_synthetixAddressResolver);
    cEther = CEther(_cETH);
    tokensTypes = ITokensTypeStorage(_tokensTypes);
  }

  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] _additionalArgs,
    bytes _additionalData
  ) external payable returns (uint256) {
    require(_source != _destination);

    uint256 receivedAmount;

    if (_source == ETH_TOKEN_ADDRESS) {
      require(msg.value == _sourceAmount);
    } else {
      require(msg.value == 0);
    }

    if (_type == uint(ExchangeType.Paraswap)) {
      // Trade via Paraswap (We can add special logic fo Paraswap here)
      receivedAmount = _trade(_source, _destination, _sourceAmount);
    }
    else if (_type == uint(ExchangeType.Bancor)) {
      // Trade via Bancor (We can add special logic fo Bancor here)
      receivedAmount = _trade(_source, _destination, _sourceAmount);
    }
    else if (_type == uint(ExchangeType.OneInch)) {
      // Trade via Bancor(We can add special logic fo Bancor here)
      receivedAmount = _trade(_source, _destination, _sourceAmount);
    }
    else if(_type == uint(ExchangeType.Synthetix)){
      // Trade via Synthetix
      receivedAmount = _tradeViaSynthetix(
          _source,
          _destination,
          _sourceAmount
      );
    }
    else {
      // unknown exchange type
      revert();
    }

    // transfer asset B back to sender
    if (_destination == ETH_TOKEN_ADDRESS) {
      (msg.sender).transfer(receivedAmount);
    } else {
      // transfer tokens received to sender
      _destination.transfer(msg.sender, receivedAmount);
    }


    emit Trade(msg.sender, _source, _sourceAmount, _destination, receivedAmount, uint8(_type));

    return receivedAmount;
  }

  // Mock for trade via Bancor, Paraswap, OneInch
  // This DEXs has the same logic
  // Transfer asset A from fund and send asset B back to fund
  function _trade(ERC20 _source, ERC20 _destination, uint256 _sourceAmount)
   private
   returns(uint256 receivedAmount)
  {
    // we can broke transfer for tests
    if(!stopTransfer){
      // transfer asset A from sender
      if (_source == ETH_TOKEN_ADDRESS) {
        receivedAmount = getValue(_source, _destination, _sourceAmount);
      } else {
        _transferFromSenderAndApproveTo(_source, _sourceAmount, NULL_ADDRESS);
        receivedAmount = getValue(_source, _destination, _sourceAmount);
      }
    }else{
      receivedAmount = 0;
    }

    setTokenType(_destination, "CRYPTOCURRENCY");
  }

  // Mock for trade via Synthetix
  // Synthetix has logic burn and mint
  // And trade can be only for Synth assests
  function _tradeViaSynthetix(
    address sourceToken,
    address destinationToken,
    uint256 sourceAmount
    )
    private
    returns(uint256 returnAmount)
  {
    // transfer from sender, and don't need additional aprove to syntetix main contract
    // because main syntetix do burn and mint
    require(ERC20(sourceToken).transferFrom(msg.sender, address(this), sourceAmount));
    ISynth from = ISynth(sourceToken);
    ISynth to = ISynth(destinationToken);

    returnAmount = synthetix.exchange(from.currencyKey(), sourceAmount, to.currencyKey());

    setTokenType(destinationToken, "SYNTHETIX");
  }

  // Possibilities:
  // * kyber.getExpectedRate
  // * kyber.findBestRate
  function getValue(address _from, address _to, uint256 _amount) public view returns (uint256) {
    // ETH case (can change rate)
    if (_to == address(ETH_TOKEN_ADDRESS)) {
      return _amount.mul(div).div(mul);
    }
    else if (_from == address(ETH_TOKEN_ADDRESS)) {
      return _amount.mul(mul).div(div);
    }
    // DAI Case (can change rate)
    else if(_to == stableCoinAddress) {
      return _amount.mul(div).div(mul);
    }
    else if(_from == stableCoinAddress) {
      return _amount.mul(mul).div(div);
    }
    // ERC case
    else {
      return _amount;
    }
  }

  function compoundRedeemByPercent(uint _percent, address _cToken)
   external
   returns(uint256)
  {
    uint256 receivedAmount = 0;

    uint256 amount = (_percent == 100)
    // if 100 return all
    ? ERC20(address(_cToken)).balanceOf(msg.sender)
    // else calculate percent
    : getPercentFromCTokenBalance(_percent, address(_cToken), msg.sender);

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

    return receivedAmount;
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
      receivedAmount = _amount;
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

    setTokenType(_cToken, "COMPOUND");

    return receivedAmount;
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
    if(_percent > 0 && _percent <= 100){
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

  // get the total value of multiple tokens and amounts in one go
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256) {
    uint256 sum = 0;

    for (uint256 i = 0; i < _fromAddresses.length; i++) {
      sum = sum.add(getValue(_fromAddresses[i], _to, _amounts[i]));
    }

    return sum;
  }

  function setRatio(uint256 _mul, uint256 _div) public {
    mul = _mul;
    div = _div;
  }

  // helper for get ratio between assets in Paraswap platform
  // NOTE this works only for synthetix assets
  // (For get value in non synthetix assets need first convert to sUSD or sETH and then use Uniswap rate)
  function getValueViaSynthetix(
    address _from,
    address _to,
    uint256 _amount
  ) public view returns (uint256 value) {
    // get latest exchangeRates instance
    IExchangeRates exchangeRates = IExchangeRates(
      synthetixAddressResolver.requireAndGetAddress(bytes32("ExchangeRates"),
      "Missing ExchangeRates address")
    );

    ISynth from = ISynth(_from);
    ISynth to = ISynth(_to);

    return exchangeRates.effectiveValue(from.currencyKey(), _amount, to.currencyKey());
  }

  function _transferFromSenderAndApproveTo(ERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, this, _sourceAmount));
    _source.approve(_to, _sourceAmount);
  }

  function changeStopTransferStatus(bool _status) public {
    stopTransfer = _status;
  }


  function setTokenType(address _token, string _type) private {
    // no need add type, if token alredy registred
    if(tokensTypes.isRegistred(_token))
      return;

    tokensTypes.addNewTokenType(_token,  _type);
  }

  function pay() public payable {}

  function() public payable {}
}

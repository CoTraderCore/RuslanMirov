pragma solidity ^0.4.24;

import "../../../contracts/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import "../synthetixMock/ISynth.sol";
import "../synthetixMock/ISynthetix.sol";
import "../synthetixMock/IAddressResolver.sol";
import "../synthetixMock/IExchangeRates.sol";

contract ExchangePortalMock {

  using SafeMath for uint256;
  // Synthetix
  ISynthetix public synthetix;
  IAddressResolver public synthetixAddressResolver;

  // KyberExchange recognizes ETH by this address, airswap recognizes ETH as address(0x0)
  ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  address constant private NULL_ADDRESS = address(0);
  // multiplyer and divider are used to set prices. X ether = X*(mul/div) token,
  // similarly X token = X*(div/mul) ether for every token where X is the amount
  uint256 public mul;
  uint256 public div;
  address public stableCoinAddress;
  bool public stopTransfer;

  // Enum
  enum ExchangeType { Paraswap, Bancor, OneInch, Synthetix}

  event Trade(address trader, address src, uint256 srcAmount, address dest, uint256 destReceived, uint8 exchangeType);

  constructor(
    uint256 _mul,
    uint256 _div,
    address _stableCoinAddress,
    address _synthetix,
    address _synthetixAddressResolver
    )
    public
  {
    mul = _mul;
    div = _div;
    stableCoinAddress = _stableCoinAddress;
    synthetix = ISynthetix(_synthetix);
    synthetixAddressResolver = IAddressResolver(_synthetixAddressResolver);
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

  function pay() public payable {}

  function() public payable {}
}

pragma solidity ^0.4.24;

contract ExchangeRates {
  uint rate = 1;

  function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
    public
    view
    returns (uint){
       return sourceAmount * rate;
   }

  function changeRate(uint newRate) public {
    rate = newRate;
  }
}

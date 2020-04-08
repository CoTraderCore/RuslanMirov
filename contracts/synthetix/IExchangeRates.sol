pragma solidity ^0.4.24;

contract IExchangeRates {
  function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
     public
     view
     returns (uint);
}

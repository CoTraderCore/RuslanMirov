pragma solidity ^0.4.24;

import "./IExchangeRates.sol";

contract ISynthetix {
  function exchange(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
    external
    returns (uint amountReceived);

  function exchangeRates() internal view returns (IExchangeRates);
}

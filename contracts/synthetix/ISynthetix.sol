pragma solidity ^0.4.24;

contract ISynthetix {
  function exchange(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
        external
        returns (uint amountReceived);
}

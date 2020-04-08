import "./ISynth.sol";
import "./IAddressResolver.sol";
import "./IExchangeRates.sol";

contract Synthetix {
  IAddressResolver addressResolver;
  IExchangeRates   exchangeRates;


  constructor(address _addressResolver, address _exchangeRates) public {
    addressResolver = IAddressResolver(_addressResolver);
    exchangeRates = IExchangeRates(_exchangeRates);
  }

  function exchange(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
    external
    returns (uint amountReceived)
    {
      address from = addressResolver.requireAndGetAddress(sourceCurrencyKey, "Can not get address");
      address to = addressResolver.requireAndGetAddress(destinationCurrencyKey, "Can not get address");

      uint rate = exchangeRates.effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

      ISynth(from).burn(msg.sender, sourceAmount);
      ISynth(to).issue(msg.sender, rate);
    }
}

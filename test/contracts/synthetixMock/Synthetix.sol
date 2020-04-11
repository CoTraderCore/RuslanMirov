import "./ISynth.sol";
import "./IAddressResolver.sol";
import "./IExchangeRates.sol";

import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Synthetix is StandardToken, DetailedERC20 {
  IAddressResolver addressResolver;
  IExchangeRates   exchangeRates;

  constructor(
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 _totalSupply,
    address _addressResolver,
    address _exchangeRates
    )
    DetailedERC20(_name, _symbol, _decimals)
    public
  {
    // Initialize totalSupply
    totalSupply_ = _totalSupply;
    // Initialize Holder
    balances[msg.sender] = _totalSupply;

    // Initialize other Synthetix network contracts instance
    addressResolver = IAddressResolver(_addressResolver);
    exchangeRates = IExchangeRates(_exchangeRates);
  }


  function exchange(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
    external
    returns (uint amountReceived)
    {
      address from = addressResolver.requireAndGetAddress(sourceCurrencyKey, "Can not get address");
      address to = addressResolver.requireAndGetAddress(destinationCurrencyKey, "Can not get address");

      // get ratio between from and to directions 
      amountReceived = exchangeRates.effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

      // burn from
      ISynth(from).burn(msg.sender, sourceAmount);
      // mint to
      ISynth(to).issue(msg.sender, amountReceived);
    }
}

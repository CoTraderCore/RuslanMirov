pragma solidity ^0.4.24;

import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Synth is StandardToken, DetailedERC20 {
  address public owner;

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _owner)
    DetailedERC20(_name, _symbol, _decimals)
    public
  {
    // Initialize totalSupply
    totalSupply_ = _totalSupply;
    // Initialize Holder
    // This contract is owner of all cEthers
    balances[address(this)] = _totalSupply;

    owner = _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function issue(address _who, uint256 _value) external onlyOwner {
    balances[_who] = balances[_who].add(_value);
    totalSupply_ = totalSupply_.add(_value);
  }

  function burn(address _who, uint256 _value) external onlyOwner {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
  }
}

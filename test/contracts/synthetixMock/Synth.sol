pragma solidity ^0.4.24;

import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Synth is StandardToken, DetailedERC20 {
  address public owner;
  bytes32 public currencyKey;

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _owner)
    DetailedERC20(_name, _symbol, _decimals)
    public
  {
    // Initialize totalSupply
    totalSupply_ = _totalSupply;
    // Initialize Holder
    balances[msg.sender] = _totalSupply;
    // Initial owner
    owner = _owner;
    // Initial synth key
    currencyKey = stringToBytes32(_symbol);
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


  // helper for convert dynamic string size to fixed bytes32 size 
  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
   }
}

pragma solidity ^0.4.24;

contract IAddressResolver {
  function requireAndGetAddress(bytes32 name, string reason) public view returns (address);
}

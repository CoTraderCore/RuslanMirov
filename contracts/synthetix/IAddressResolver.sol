pragma solidity ^0.4.24;

contract IAddressResolver {
  function getAddress(bytes32 name) public view returns (address);
  function requireAndGetAddress(bytes32 name, string reason) public view returns (address);
}

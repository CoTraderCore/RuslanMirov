pragma solidity ^0.4.24;

contract AddressResolver {
  mapping(bytes32 => address) public repository;

  function addAddress(bytes32 name, address _address) public {
    repository[name] = _address;
  }

  function getAddress(bytes32 name) public view returns (address) {
    return repository[name];
  }

  function requireAndGetAddress(bytes32 name, string reason) public view returns (address) {
    address _foundAddress = repository[name];
    require(_foundAddress != address(0), reason);
    return _foundAddress;
  }
}

pragma solidity ^0.4.24;

contract AddressResolver {
  mapping(bytes32 => address) public repository;

  function addAddress(string name, address _address) public {
    bytes32 key = stringToBytes32(name);
    repository[key] = _address;
  }

  function getAddress(bytes32 name) public view returns (address) {
    return repository[name];
  }

  function requireAndGetAddress(bytes32 name, string reason) public view returns (address) {
    address _foundAddress = repository[name];
    require(_foundAddress != address(0), reason);
    return _foundAddress;
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

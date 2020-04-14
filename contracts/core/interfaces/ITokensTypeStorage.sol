contract ITokensTypeStorage {
  mapping(address => bool) public isRegistred;

  mapping(address => bytes32) public getType;

  mapping(address => bool) public isPermittedAddress;

  address public owner;

  function addNewTokenType(address _token, string _type) public;
}

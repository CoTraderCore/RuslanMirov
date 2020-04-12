pragma solidity ^0.4.24;

/**
* Logic: Permitetd addresses can write to this contract types of converted tokens
*
* Motivation:
* Due fact tokens can be different like Uniswap/Bancor pool, Synthetix, Compound ect
* we need a certain method for convert a certain token.
* so we mark type for new token once after success convert
*/

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";

contract TokensTypeStorage is Ownable {
  // checkl if token alredy registred
  mapping(address => bool) public isRegistred;
  // tokens types
  mapping(address => string) public getType;
  // addresses which can write to this contract
  mapping(address => bool) public isPermittedAddress;

  // all available types
  string[] public allTypes;

  modifier onlyPermitted() {
    require(isPermittedAddress[msg.sender]);
    _;
  }

  function addNewTokenType(address _token, string _type) public onlyPermitted {
    getType[_token] = _type;
    isRegistred[_token] = true;
    allTypes.push(_type);
  }

  function addNewPermittedAddress(address _permitted) public onlyOwner {
    isPermittedAddress[_permitted] = true;
  }

  function removePermittedAddress(address _permitted) public onlyOwner {
    isPermittedAddress[_permitted] = false;
  }
}

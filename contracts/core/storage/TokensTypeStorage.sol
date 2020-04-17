pragma solidity ^0.4.24;

/**
* Logic: Permitetd addresses can write to this contract types of converted tokens
*
* Motivation:
* Due fact tokens can be different like Uniswap/Bancor pool, Synthetix, Compound ect
* we need a certain method for convert a certain token.
* so we mark type for new token once after success convert
*/

import "../../zeppelin-solidity/contracts/access/Ownable.sol";

contract TokensTypeStorage is Ownable {
  // check if token alredy registred
  mapping(address => bool) public isRegistred;
  // tokens types
  mapping(address => bytes32) public getType;
  // addresses which can write to this contract
  mapping(address => bool) public isPermittedAddress;

  // all available types
  string[] public allTypes;

  modifier onlyPermitted() {
    require(isPermittedAddress[msg.sender], "Sender not have permition for edit this contract");
    _;
  }

  function addNewTokenType(address _token, string _type) public onlyPermitted {
    getType[_token] = stringToBytes32(_type);
    isRegistred[_token] = true;
    allTypes.push(_type);
  }

  function addNewPermittedAddress(address _permitted) public onlyOwner {
    isPermittedAddress[_permitted] = true;
  }

  function removePermittedAddress(address _permitted) public onlyOwner {
    isPermittedAddress[_permitted] = false;
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

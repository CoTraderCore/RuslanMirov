pragma solidity ^0.4.24;
/**
* This contract convert source ERC20 token to destanation token
* support sources 1INCH, COMPOUND, SYNTHETIX, BANCOR/UNISWAP pools
*/

import "../interfaces/ExchangePortalInterface.sol";
import "../interfaces/PermittedStabelsInterface.sol";
import "../interfaces/PoolPortalInterface.sol";
import "../interfaces/ITokensTypeStorage.sol";


contract ConvertPortal {
  function convert (address _source, uint256 _sourceAmount, address _destination) external {

  }
}

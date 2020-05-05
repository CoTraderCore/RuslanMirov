pragma solidity ^0.4.24;

import "../zeppelin-solidity/contracts/token/ERC20/IERC20.sol";


contract IOneSplitAudit {
  function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 disableFlags
    ) public payable;

  function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 featureFlags // See contants in IOneSplit.sol
    )
      public
      view
      returns(
          uint256 returnAmount,
          uint256[] memory distribution
      );
}

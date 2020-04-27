// NO NEED FOR MAINNET
// THIS need ONLY FOR ROPSTEN test!!!
pragma solidity ^0.4.24;

contract OneSplitMock {
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
    )
    {
      returnAmount = amount;
      distribution = new uint256[](2);
      distribution[0] = 1;
      distribution[1] = 1;
    }
}

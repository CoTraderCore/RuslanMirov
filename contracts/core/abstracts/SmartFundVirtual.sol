import "../../zeppelin-solidity/contracts/token/ERC20/IERC20.sol";
// DAI and ETH have different implements of this methods
abstract contract SmartFundVirtual {
  function calculateFundValue() public virtual view returns (uint256);
  function getTokenValue(IERC20 _token) public virtual view returns (uint256);
}

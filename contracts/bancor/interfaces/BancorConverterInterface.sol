import "../../zeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface BancorConverterInterface {
  IERC20[] public connectorTokens;
  function fund(uint256 _amount) external;
  function liquidate(uint256 _amount) external;
  function getConnectorBalance(IERC20 _connectorToken) external view returns (uint256);
}

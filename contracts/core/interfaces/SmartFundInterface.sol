import "../../zeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface SmartFundInterface {
  // sends percentage of fund tokens to the user
  // function withdraw() external;
  function withdraw(uint256 _percentageWithdraw, bool _convert) external;

  // for smart fund owner to trade tokens
  function trade(
    IERC20 _source,
    uint256 _sourceAmount,
    IERC20 _destination,
    uint256 _type,
    bytes32[] calldata dditionalArgs,
    bytes calldata _additionalData,
    uint256 _minReturn
  )
    external;

  function buyPool(
    uint256 _amount,
    uint _type,
    IERC20 _poolToken
  )
    external;

  function sellPool(
    uint256 _amount,
    uint _type,
    IERC20 _poolToken
  )
    external;

  // calculates the number of shares a buyer will receive for depositing `amount` of ether
  function calculateDepositToShares(uint256 _amount) external view returns (uint256);

  function fundManagerWithdraw(bool _convert) external;
}

interface IContractRegistry {
    function addressOf(bytes32 calldata _contractName) external view returns (address);
    // deprecated, backward compatibility
    function getAddress(bytes32 calldata _contractName) external view returns (address);
}

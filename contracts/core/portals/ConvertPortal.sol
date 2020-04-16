pragma solidity ^0.4.24;
/**
* This contract convert source ERC20 token to destanation token
* support sources 1INCH, COMPOUND, SYNTHETIX, BANCOR/UNISWAP pools
*/

import "../interfaces/ExchangePortalInterface.sol";
import "../interfaces/PoolPortalInterface.sol";
import "../interfaces/ITokensTypeStorage.sol";
import "../../CToken";
import "../../zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";

contract ConvertPortal {
  address constant private ETH_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  bytes32[] private BYTES32_EMPTY_ARRAY = new bytes32[](0);
  address public CEther;
  ExchangePortalInterface public exchangePortal;
  PoolPortalInterface public poolPortal;
  ITokensTypeStorage  public tokensTypes;

  /**
  * @dev contructor
  *
  * @param _exchangePortal         address of exchange portal
  * @param _poolPortal             address of pool portal
  * @param _tokensTypes            address of the tokens type storage
  * @param _CEther                 address of Compound ETH wrapper
  */
  constructor(
    address _exchangePortal,
    address _poolPortal,
    address _tokensTypes,
    address _CEther
    )
    public
  {
    exchangePortal = ExchangePortalInterface(_exchangePortal);
    poolPortal = PoolPortalInterface(_poolPortal);
    tokensTypes = ITokensTypeStorage(_tokensTypes);
    CEther = _CEther;
  }

  // helper for convert Compound asset
  function convertCompound(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {
    // step 1 convert cToken to underlying
    CToken(_source).redeem(_sourceAmount);

    // step 2 get underlying address and received underlying amount
    address underlyingAddress = (_source == CEther)
    ? ETH_TOKEN_ADDRESS
    : CToken(_source).underlying();

    uint256 underlyingAmount = (_source == CEther)
    ? address(this).balance
    : ERC20(_source).balanceOf(address(this));

    // step 3 convert underlying to destination if _destination != underlyingAddress
    if(_destination != underlyingAddress){
      //convert via 1inch
      uint256 destAmount = exchangePortal.trade(
        ERC20(underlyingAddress),
        underlyingAmount,
        ERC20(_destination),
        2,
        BYTES32_EMPTY_ARRAY,
        "0x"
      );
      return destAmount;
    }else{
      return underlyingAmount;
    }

  }

  // helper for convert Unswap asset
  function convertUniswapPool(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {

  }

  // helper for convert Syntetix asset
  function convertSynthetix(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {

  }

  // helper for convert Syntetix asset
  function convertCryptocurency(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {
    _transferFromSenderAndApproveTo(ERC20(_source), _sourceAmount, address(exchangePortal));
    // Convert crypto via 1inch aggregator
    uint256 destAmount = exchangePortal.trade(
      ERC20(_source),
      _sourceAmount,
      ERC20(_destination),
      2,
      BYTES32_EMPTY_ARRAY,
      "0x"
    );

    return destAmount;
  }

  // helper for convert Syntetix asset
  function convertBancorPool(address _source, uint256 _sourceAmount, address _destination)
    private
    returns(uint256)
  {
    _transferFromSenderAndApproveTo(ERC20(_source), _sourceAmount, address(exchangePortal));
    // Convert BNT pools via Bancor DEX
    uint256 destAmount = exchangePortal.trade(
      ERC20(_source),
      _sourceAmount,
      ERC20(_destination),
      1,
      BYTES32_EMPTY_ARRAY,
      "0x"
    );

    return destAmount;
  }


  // convert CRYPTOCURRENCY, COMPOUND, SYNTHETIX, BANCOR/UNISWAP pools to _destination asset
  function convert(address _source, uint256 _sourceAmount, address _destination) external {
    uint256 receivedAmount = 0;
    // convert assets
    if(tokensTypes.getType(_source) == bytes32("CRYPTOCURRENCY")){
      receivedAmount = convertCryptocurency(_source, _sourceAmount, _destination);
    }
    else if (tokensTypes.getType(_source) == bytes32("BANCOR POOL")){
      receivedAmount = convertBancorPool(_source, _sourceAmount, _destination);
    }
    else if (tokensTypes.getType(_source) == bytes32("UNISWAP POOL")){
      receivedAmount = convertUniswapPool(_source, _sourceAmount, _destination);
    }
    else if (tokensTypes.getType(_source) == bytes32("COMPOUND")){
      receivedAmount = convertCompound(_source, _sourceAmount, _destination);
    }
    else if(tokensTypes.getType(_source) == bytes32("SYNTHETIX")){
      receivedAmount = convertSynthetix(_source, _sourceAmount, _destination);
    }
    else {
      // Unknown type
      revert();
    }

    // send back assets to sender
    if (_destination == ETH_TOKEN_ADDRESS) {
      (msg.sender).transfer(receivedAmount);
    } else {
      // transfer tokens received to sender
      ERC20(_destination).transfer(msg.sender, receivedAmount);
    }

    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = ERC20(_source).balanceOf(address(this));

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      ERC20(_source).transfer(msg.sender, endAmount);
    }
  }

  /**
  * @dev Transfers tokens to this contract and approves them to another address
  *
  * @param _source          Token to transfer and approve
  * @param _sourceAmount    The amount to transfer and approve (in _source token)
  * @param _to              Address to approve to
  */
  function _transferFromSenderAndApproveTo(ERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, address(this), _sourceAmount));

    _source.approve(_to, _sourceAmount);
  }

  // fallback payable function to receive ether from other contract addresses
  function() public payable {}
}

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

  // convert CRYPTOCURRENCY, COMPOUND, SYNTHETIX, BANCOR/UNISWAP pools to _destination asset
  function convert(address _source, uint256 _sourceAmount, address _destination) external {
    // convert assets
    if(tokensTypes.getType(_source) == bytes32("CRYPTOCURRENCY")){
      // Convert via 1inch aggregator
      exchangePortal.trade(ERC20(_source), _sourceAmount, ERC20(_destination), 2, BYTES32_EMPTY_ARRAY, "0x");
    }
    else if (tokensTypes.getType(_source) == bytes32("BANCOR POOL")){
      // Convert BNT pools via Bancor DEX
      exchangePortal.trade(ERC20(_source), _sourceAmount, ERC20(_destination), 1, BYTES32_EMPTY_ARRAY, "0x");
    }
    else if (tokensTypes.getType(_source) == bytes32("UNISWAP POOL")){
      convertUniswap(_source, _sourceAmount, _destination);
    }
    else if (tokensTypes.getType(_source) == bytes32("COMPOUND")){
      convertCompound(_source, _sourceAmount, _destination);
    }
    else if(tokensTypes.getType(_source) == bytes32("SYNTHETIX")){
      convertSynthetix(_source, _sourceAmount, _destination);
    }
    else {
      // Unknown type
      revert();
    }

    // send back assets to sender
    if(_destination == ETH_TOKEN_ADDRESS){

    }else{

    }
  }

  // helper for convert Compound asset
  function convertCompound(address _source, uint256 _sourceAmount, address _destination) private {
    // step 1 convert cToken to underlying
    CToken(_source).redeemUnderlying(_sourceAmount);

    // step 2 get underlying address and received underlying amount
    address underlyingAddress = (_source == CEther)
    ? ETH_TOKEN_ADDRESS
    : CToken(_source).underlying();

    uint256 underlyingAmount = (_source == CEther)
    ? address(this).balance
    : ERC20(_source).balanceOf(address(this));

    // step 3 convert underlying to destination if _destination != underlyingAddress
    if(_destination != underlyingAddress)
      //convert via 1inch
      exchangePortal.trade(
        ERC20(underlyingAddress),
        underlyingAmount,
        ERC20(_destination),
        2,
        BYTES32_EMPTY_ARRAY,
        "0x"
      );
  }

  // helper for convert Unswap asset
  function convertUniswap(address _source, uint256 _sourceAmount, address _destination) private {

  }

  // helper for convert Syntetix asset
  function convertSynthetix(address _source, uint256 _sourceAmount, address _destination) private {

  }
}

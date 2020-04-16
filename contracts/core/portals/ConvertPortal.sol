pragma solidity ^0.4.24;
/**
* This contract convert source ERC20 token to destanation token
* support sources 1INCH, COMPOUND, SYNTHETIX, BANCOR/UNISWAP pools
*/

import "../interfaces/ExchangePortalInterface.sol";
import "../interfaces/PoolPortalInterface.sol";
import "../interfaces/ITokensTypeStorage.sol";


contract ConvertPortal {
  ERC20 constant private ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  ExchangePortalInterface public exchangePortal;
  PoolPortalInterface public poolPortal;
  ITokensTypeStorage  public tokensTypes;

  /**
  * @dev contructor
  *
  * @param _exchangePortal         address of exchange portal
  * @param _poolPortal             address of pool portal
  * @param _tokensTypes            address of the tokens type storage
  */
  constructor(
    address _exchangePortal,
    address _poolPortal,
    address _tokensTypes
    )
    public
  {
    exchangePortal = ExchangePortalInterface(_exchangePortal);
    poolPortal = PoolPortalInterface(_poolPortal);
    tokensTypes = ITokensTypeStorage(_tokensTypes);
  }

  function convert (address _source, uint256 _sourceAmount, address _destination) external {
    // convert assets
    if(tokensTypes.getType(_from) == bytes32("CRYPTOCURRENCY")){
      // Convert via 1inch aggregator
      exchangePortal.trade(_source, _sourceAmount, _destination, 2, [], "0x", 1);
    }
    else if (tokensTypes.getType(_from) == bytes32("BANCOR POOL")){
      // Convert via Bancor DEX
      exchangePortal.trade(_source, _sourceAmount, _destination, 1, [], "0x", 1);
    }
    else if (tokensTypes.getType(_from) == bytes32("UNISWAP POOL")){

    }
    else if (tokensTypes.getType(_from) == bytes32("COMPOUND")){

    }
    else if(tokensTypes.getType(_from) == bytes32("SYNTHETIX")){

    }
    else {
      // Unknown type
      revert();
    }

    // send back assets to sender
    if(_to == ETH_TOKEN_ADDRESS){

    }else{

    }
  }

  function convertCompound() private {

  }

  function convertUniswap() private {

  }

  function convertSynthetix() private {

  }
}

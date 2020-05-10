
# Updates
```
0) Migrate to Solidity 6.0
1) Added both aggregators 1inch and Parawap
2) Convert assets to ETH or USD before withdraw
3) Add min return for trade
4) Add tokens type storage
```


# Run tests

```
NOTE: in separate console

0) npm i
1) npm run ganache  
2) truffle test
```


# Note for TokensTypeStorage contract
```
If You depoloy new Exchange Portal or Pool Portal or any new contract which use TokensTypeStorage

You need execude TokensTypeStorage.addNewPermittedAddress(YourNewContractAddress)

This means You permitted for write for new Exchange/Pool portal (or any another contract which use TokensTypeStorage as writer)

Otherwise, you will receive errors when trying to add a new token type (For Buy/Sell/Swap tokens)

```

# Note for Permitted contracts

```
After deploy new Convert, Exchange or pool Portal don't forget add this new address in Permitted contract
The same for add new Stable coin address, You need add this address to special Permitted contract  
```


# Note for Compound Mint ERC20
```
For some reason mint ERC20 not works in Exchange portal for Ropsten, but works good for Mainnet  

Details:
https://stackoverflow.com/questions/61572243/erc20-transferfrom-not-working-yes-ive-checked-allowance

Mainnet mint success tx example via Portal  
https://etherscan.io/tx/0x3c0b7c4e78f26d6db6a64620db33a2db45a478ae86de7b42cd8419253589cc6c
```

# Addresses

```
Smart Fund registry

0xd81736Eb54D4FbCDF8779E0b488dd1a5f12F2f17

https://etherscan.io/tx/0x6bcd03dc664cb711e3a73dea8868a3f119e9eb1757e87d5307119659ba8bcee3


Tokens Type Storage

0x37ff4bc9a425F37d3Af95662c9D88A88d05f3417

https://etherscan.io/tx/0x8aea1d0522615b4cf08b8ab6d4a24a7b281c847702e812b2d9573ab151595fdf


Permitted Pools

0x65743d807839D4A9a0D7986A09D12698D6138766

https://etherscan.io/tx/0x52a78b294f9c96cd51b0cede03aa7b0118a51182e9e4a4a7986e3d4bbfa8f966


(Enable optimization)

Pool Portal

0xd63495461cA711d59e480AC5c3827B7f7C334Fb3

https://etherscan.io/tx/0xd6ccc094d59ead16c3361ffab61eeb9d480dd6e78aceafa1fa394764c5043114



Permitted Exchanges

0xB55AAd20a6c310a5E4B68C3fF1Abe5E3ba1B7fFb

https://etherscan.io/tx/0x8d17e3b13359b7627b514fa437cb26db2092f445c634bdded62dbf1ab745d82c

(Enable optimization)

ExchangePortal

0xa145eCA55AE0E39D7c228ed7A962424a97AC74cB

https://etherscan.io/tx/0xe093c2d649e757798dfc2d89aeaed1976428ccc6f6ac61abfd3b8e5b2c706139


Permitted Stables

0x3621c85a4F3A4dCFF575550C5e1916b9bA4aeebd

https://etherscan.io/tx/0xdb03759831e93da73d1dbb85359907de754ac245d8ede08874d6cc69bef11797


Permitted Converts

0x6666fc23ae6c26e8500ccd55a870cd4ede49202c

https://etherscan.io/tx/0x53e4ce06594a6e57e08d8b588a760e359655286a87569dd14bd46bcfa1711179


Convert Portal

0xA6A40e3c70710Be8D137F66A2697c8227821CD6c

https://etherscan.io/tx/0x74cffc569d816a50be5991901b9ebeed91110778a2437c32aec3750aa3ba5864



(Enable optimization)

ETH FACTORY

0x9e8991f78367af819188e1a2aa6c9474bc48e696

https://etherscan.io/tx/0xf5bea39269046f7dbced7daa2d5b7f9cad66f5a17c70df0c0477b7e2b0757404


(Enable optimization)

USD FACTORY

0xea7c52716e07d8ff83d8f6e042f7c6105f5818b0

https://etherscan.io/tx/0x58092737a36e20f318568c5b8d0347bb6695e32c7e99e24c85994fc8e2f3d47d



CoTraderDAOWallet

0xC9d742f23b4F10A3dA83821481D1B4ED8a596109



Stable Coin Address (DAI)

0x6B175474E89094C44Da98b954EedeAC495271d0F


GetBancorAddressFromRegistry (Wrapper)

0x178c68aefdcae5c9818e43addf6a2b66df534ed5


Bancor ETH (Wrapper)

0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315


Bancor Ratio (Wrapper)

0x3079a42efbd0027318baa0dd81d002c0929b502c


Kyber Network Proxy

0x818E6FECD516Ecc3849DAf6845e3EC868087B755


COT ERC20

0x5c872500c00565505F3624AB435c222E558E9ff8


ParaswapAugustus

0xF92C1ad75005E6436B4EE84e88cB23Ed8A290988


ParaswapPrice

0x12295f06DA62693086F5DA45b78e20B778060853


Paraswap Params

0x0595aaa68ad0fbeacdeeaa7b7d78f22717ade957


Uniswap Factory

0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95


Compound CEther

0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5


1inch

0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E

```

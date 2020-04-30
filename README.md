
# Updates
```
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


# Note
```
If You trying trade and get revert with Fail with error 'Sender not have permition for edit this contract'

This means You need add Your new Exchange/Pool portal to Tokens Type storage permitted for write

TokensTypeStorage.addNewPermittedAddress(YourNewAddress)
```

# Addresses

```
Smart Fund Registry

https://etherscan.io/tx/0x720dc9b18779b3b623868cab86e1356404ec08b5008c66d9bedbd879cddd74d4



Tokens Type Storage

0x67d635A86D5BFF3D3742a93761bE0e272BB7541e

https://etherscan.io/tx/0xcfe256487d4b038800bb042c05060b66ccf057dd8b154ff8094f5914531bc4ab


Permitted Pools

0x65743d807839D4A9a0D7986A09D12698D6138766

https://etherscan.io/tx/0x52a78b294f9c96cd51b0cede03aa7b0118a51182e9e4a4a7986e3d4bbfa8f966


Pool Portal

0x01fa1B31766c0e58a2C66b6FBa3C36128aea60E4

https://etherscan.io/tx/0x12ae8431baa3d734c33aa3e6258b5869148c9a23c9fd3cab8e30c615e8aaeb97


Permitted Stables

0x3621c85a4F3A4dCFF575550C5e1916b9bA4aeebd

https://etherscan.io/tx/0xdb03759831e93da73d1dbb85359907de754ac245d8ede08874d6cc69bef11797



Permitted Exchanges

0xB55AAd20a6c310a5E4B68C3fF1Abe5E3ba1B7fFb

https://etherscan.io/tx/0x8d17e3b13359b7627b514fa437cb26db2092f445c634bdded62dbf1ab745d82c


Exchange Portal

0xDABB0a62894A19C0D4Cb86BEd6cFdfeE7c4652c2

https://etherscan.io/tx/0x9c80c4f5d709fa1e9fde89139616b92c18071e2795d49c274654bfa4c67f4f0e


Permitted Converts

0x6666fc23ae6c26e8500ccd55a870cd4ede49202c

https://etherscan.io/tx/0x53e4ce06594a6e57e08d8b588a760e359655286a87569dd14bd46bcfa1711179



Convert Portal

0x77B71a9b0A047A075A905863993f0B455daB00e1

https://etherscan.io/tx/0x196d5f00f234e9fa6a296dfc0aded98829af00cd23e8e4f819ea6afac6d54b7f



Smart Fund ETH Factory

0x14f3a15911c35724490a603099dfdd2ec799d31a

https://etherscan.io/tx/0x16f4bd5d8a4b579cf28033bb6316a2cc84e3684ea583a1be94ee43059d879250


Smart Fund USD Factory

0x814ef7F34F4086b655dCf3603D5fF31CFFa9012a

https://etherscan.io/tx/0xb70ed3bab50c7252737dbff0bc563953a583a1061e5d4758bb5d1f36eb108d72



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

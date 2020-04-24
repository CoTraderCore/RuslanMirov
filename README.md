# Status
```
Not finished
```


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

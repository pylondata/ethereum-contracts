# Pylon token contract v0.1.1 (alpha)

Pylon token is a **smart-contract-based token**, which enables to invest in renewable energy installations.

Total Supply: 3000000000000000000000000
<br>
Token name: Pylon Token
<br>
Decimal Units: 18
<br>
Token symbol: PYLNT
<br>
Max percentage: 10
<br>
Minutes for investment: 2000

## Warning

Pylon token is a work in progress. Make sure you understand the risks before using it.

# The Smart Token Standard

## Motivation

This smart contract allow to invest in future installations.

## Specification

### SmartToken

First and foremost, a Smart Token is also an ERC-20 compliant token.
As such, it implements both the standard token methods and the standard token events.

### Methods

Note that these methods can only be executed by the token owner.

**transferOwnership**
```cs
function transferOwnership(address newOwner)
```
Transfer the owner ship of the contract to other address.
<br>
<br>
<br>
**setMinBalance**
```cs
function setMinBalance(uint minimumBalanceInFinney)
```
Set min balance of pylon token to have in the account.
<br>
<br>
<br>
**freezeAccount**
```cs
function freezeAccount(address target, bool freeze)
```
Lock account for not allow transfers.
<br>
<br>
<br>
**lock**
```cs
function lock(string newBuyLock, string newSellLock,uint256 panicBuyCounterU,uint256 panicSellCounterU)
```
Set new lock parameters for buy or sale tokens.
<br>
<br>
<br>
**setSpread**
```cs
function setSpread(uint8 Spread)
```
Set a fix spreat between sell and buy orders.
<br>
<br>
<br>
**setPanic**
```cs
function setPanic(uint8 panicLevelU, uint256 panicTimeU)
```
Set panic level and panic time.
<br>
<br>
<br>
**withdraw**
```cs
function withdraw(uint value)
```
Send eth to owner address.
<br>
<br>
<br>
**changeInvestmentRules**
```cs
function changeInvestmentRules(uint maxPercentageForInvestments, uint minutesForInvestment)
```
Change rules for new investment offer.
<br>
<br>
<br>
**changeInvestmentRules**
```cs
function newInvestmentOffer(address beneficiary, uint etherAmount, string JobDescription, bytes transactionBytecode)
```
Add new investment offer to mint Pylon Token and get part of new renewable installation.
<br>
<br>
<br>
### Events

**InvestmentOfferAdded**
```cs
event InvestmentOfferAdded(uint proposalID, address recipient, uint amount, string description)
```
Triggered when an investment offer is added.
<br>
<br>
<br>
**Invested**
```cs
event Invested(uint proposalID, address investor, string justification)
```
Triggered when a new investment is done.
<br>
<br>
<br>
**ChangeOfRules**
```cs
event ChangeOfRules(uint maxPercentage, uint investmentOfferPeriodInMinutes)
```
Triggered when the investment rules change.
<br>
<br>
<br>
**FrozenFunds**
```cs
event FrozenFunds(address target, bool frozen)
```
Triggered when account is locked.
<br>
<br>
<br>
**FrozenFunds**
```cs
event FrozenFunds(address target, bool frozen)
```
Triggered when account is locked.
<br>
<br>
<br>

# Pylon Token contract stantard functions

The following section describes standard functions a Pylon Token user can implement.

## Motivation

Those will allow dapps and wallets to buy, sell the token and invest in new renewable energy installations using the token.

The most important here is `change`.

## Specification

### Methods

**transfer**
```cs
function transfer(address _to, uint256 _value)
```
Transfer tokens to other address.
<br>
<br>
<br>
**approve**
```cs
function approve(address _spender, uint256 _value)
```
Allow another contract to spend some tokens in your behalf.
<br>
<br>
<br>
**reserves**
```cs
function approveAndCall(address _spender, uint256 _value, bytes _extraData)
```
Approve and then communicate the approved contract in a single tx.
<br>
<br>
<br>
**transferFrom**
```cs
function transferFrom(address _from, address _to, uint256 _value)
```
Transfer from an address to other address.
<br>
<br>
<br>
**transferFrom**
```cs
function transferFrom(address _from, address _to, uint256 _value)
```
Transfer from an address to other address.
<br>
<br>
<br>
**panic**
```cs
function panic(uint256 panicWallU)
```
Declare panic mode or not.
<br>
<br>
<br>
**status**
```cs
function status(uint256 sellAmount, uint256 buyAmount)
```
Recalculate the price.
<br>
<br>
<br>
**buy**
```cs
function buy()
```
Buy tokens to a seller.
<br>
<br>
<br>
**sell**
```cs
function sell()
```
Sell tokens.
<br>
<br>
<br>
**deposit**
```cs
function deposit()
```
Add ethers to contract.
<br>
<br>
<br>
**checkInvestmentOfferCode**
```cs
function checkInvestmentOfferCode( uint investmentNumber, address beneficiary, uint etherAmount, bytes transactionBytecode)
```
Function to check if a investment offer code matches.
<br>
<br>
<br>
**invest**
```cs
function invest(uint investmentNumber, string justificationText, address target)
```
Invest ethers to a new investment offer and get tokens and part of a renewable energy installation.
<br>
<br>
<br>


### Events

**LogDeposit**
```cs
event LogDeposit(address sender, uint amount)
```
Triggered when a deposit is done.
<br>
<br>
<br>
**LogWithdrawal**
```cs
event LogWithdrawal(address receiver, uint amount)
```
Triggered when a withdrawal is done.
<br>
<br>
<br>
**LogBuy**
```cs
event LogBuy(address receiver, uint amount)
```
Triggered when a buy is done.
<br>
<br>
<br>
**LogTransfer**
```cs
event LogTransfer(address sender, address to, uint amount)
```
Triggered when a transfer is done.
<br>
<br>
<br>
**Transfer**
```cs
event Transfer(address indexed from, address indexed to, uint256 value)
```
This generates a public event on the blockchain that will notify clients.
<br>
<br>
<br>


## Testing
Testing mode.


## LINKS

- [WEB Pylon Network](http://pylon-network.org/)
- [Download WhitePaper ENGLISH version](http://pylon-network.org/wp-content/uploads/2017/07/170730_WP-PYLON_EN.pdf)
- [Download WhitePaper SPANISH version](http://pylon-network.org/wp-content/uploads/2017/07/170730_WP-PYLON_ES.pdf)
- [BitcoinTalk Channel](https://bitcointalk.org/index.php?topic=2054297)
- [BitcoinTalk Spanish Channel](https://bitcointalk.org/index.php?topic=2055169)
- [Telegram Official Channel](https://t.me/pylonnetworkofficialtelegram)
- [Telegram Spanish Channel](https://t.me/pylonnetworkspanishchannel)
- [Twitter](https://twitter.com/KlenergyTech)
- [WEB Klenergy Tech](http://klenergy-tech.com/)
- [METRON](http://metron.es)
- [Facebook](https://www.facebook.com/KlenergyTechOfficial/s)
- [LinkedIn]( https://www.linkedin.com/company-beta/10229571/)


## License

Pylon token is open source and distributed under the Apache License v2.0

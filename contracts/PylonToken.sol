pragma solidity ^0.4.4;

import "./ConvertLib.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    //transfer owner property
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract PylonToken is owned {
	/* Public variables of the token */
	string public standard = "Pylon Token - The first decentralized energy exchange platform powered by renewable energy";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

	uint256 public buyPrice=174000000000000000000;
  uint256 public sellPrice=168000000000000000000;
  string public buyLock="open";
  string public sellLock="open";
  uint8 public spread=5;
  uint8 public panicLevel=30;
  uint256 public panicTime=60*2;
  uint256 public time;
  uint256 public lastBlock=block.number;
  uint256 public panicSellCounter;
  uint256 public panicBuyCounter;
  uint256 public panicWall;
  string public debug;

	uint public maxPercentage;
  uint public investmentOfferPeriodInMinutes;
  InvestmentOffer[] public investmentOffer;
  uint public numInvestmentOffers;
	address congressLeader;

	mapping (address => bool) public frozenAccount;

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint256)) public allowance;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	/* This generates a public event on the blockchain that will notify clients */
  event FrozenFunds(address target, bool frozen);

	function PylonToken(
		/*
    uint256 initialSupply=3000000000000000000000000,
    string tokenName = "Pylon Token",
    uint8 decimalUnits = 18,
    string tokenSymbol = "PYLNT",
		uint maxPercentage = 10,
    uint minutesForInvestment = 200,
    address congressLeader
		*/

  ) {
		balances[tx.origin] = 3000000000000000000000000;
		totalSupply = 3000000000000000000000000;                        // Update total supply
    name = "Pylon Token";                                   // Set the name for display purposes
    symbol = "PYLNT";                               // Set the symbol for display purposes
    decimals = 18;
		maxPercentage = 10;
    uint minutesForInvestment = 200;

		changeInvestmentRules(maxPercentage, minutesForInvestment);

		if (congressLeader != 0) owner = congressLeader;

	}

	function transfer(address _to, uint _value) returns(bool sufficient) {
		if (balances[msg.sender] < _value) revert();               					// Check if the sender has enough
		if (balances[_to] + _value < balances[_to]) revert();  // Check for overflows
		if (frozenAccount[msg.sender]) revert();                // Check if frozen

		balances[msg.sender] -= _value;
		balances[_to] += _value;
		Transfer(msg.sender, _to, _value);

		if(msg.sender.balance<minBalanceForAccounts)
    sell((minBalanceForAccounts-msg.sender.balance)/sellPrice); // refill the balance of the sender


		return true;
	}

	//Set min balance of tokens to have in account
  uint minBalanceForAccounts;

  function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
     minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
  }

	function getBalanceInEth(address addr) returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) returns(uint) {
		return balances[addr];
	}

	/* Allow another contract to spend some tokens in your behalf */
  function approve(address _spender, uint256 _value)
      returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      return true;
  }

	/* Approve and then communicate the approved contract in a single tx */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
      returns (bool success) {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
          return true;
      }
  }

	/* A contract attempts to get the coins */
  function transferFrom(address _from, address _to, uint256 _value) onlyOwner returns (bool success) {
			if (frozenAccount[_from]) revert();                        // Check if frozen
			if (balances[_from] < _value) revert();                 // Check if the sender has enough
      if (balances[_to] + _value < balances[_to]) revert();  // Check for overflows
      if (_value > allowance[_from][msg.sender]) revert();   // Check allowance

			balances[_from] -= _value;                          // Subtract from the sender
      balances[_to] += _value;                            // Add the same to the recipient
      allowance[_from][msg.sender] -= _value;

			Transfer(_from, _to, _value);

			return true;
  }

	// Lock account for not allow transfers
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    //set new lock parameters for buy or sale tokens
    function lock(string newBuyLock, string newSellLock,uint256 panicBuyCounterU,uint256 panicSellCounterU) onlyOwner {
        buyLock = newBuyLock;
        sellLock = newSellLock;
        panicSellCounter=panicSellCounterU;
        panicBuyCounter=panicBuyCounterU;
    }

    //set a fix spreat between sell and buy orders
    function setSpread(uint8 Spread) onlyOwner {
        spread=Spread;
    }

    //set panic level and panic time
    function setPanic(uint8 panicLevelU, uint256 panicTimeU) onlyOwner {
        panicLevel=panicLevelU;
        panicTime=panicTimeU;
    }

    //Declare panic mode or not
    function panic(uint256 panicWallU){
        time=block.timestamp;

        //calculate the panic wall, this is the limit for buy or sell between specific panic time
        panicWallU=(totalSupply*panicLevel)/100;
        panicWall=panicWallU*buyPrice;

        //check if the panic counter is more than the panic wallet to close sell orders or buy orders
        if(panicBuyCounter>=(panicWallU*buyPrice)){
         buyLock = "close";
        }else{
            buyLock="open";
        }
        if(panicSellCounter>=(panicWallU*sellPrice)){
            sellLock = "close";
        }else{
            sellLock="open";
        }

    }

    //Declare logging events
    event LogDeposit(address sender, uint amount);
    event LogWithdrawal(address receiver, uint amount);
    event LogBuy(address receiver, uint amount);
    event LogTransfer(address sender, address to, uint amount);

    function status(uint256 sellAmount, uint256 buyAmount){

        //stablish the buy price & sell price with the spread configured in the contract
        buyPrice=(this.balance/totalSupply)*100000000;
        sellPrice=buyPrice+(buyPrice*spread)/100;

        //add to the panic counter the amount of sell or buy
        panicBuyCounter=panicBuyCounter+buyAmount;
        panicSellCounter=panicSellCounter+sellAmount;

        //get the block numer to compare with the last block
        uint reset=block.number;

        //compare if happends enougth time between the last and the current block with the contract configuration
        if((reset-lastBlock)>=(panicTime/15)){
        //if the time is more than the panic time we reset the counter for the next checks
        panicBuyCounter=0+buyAmount;
        panicSellCounter=0+sellAmount;
        //aisgn the new last block
        lastBlock=block.number;
        }

        //activate or desactivae panic mode
        panic(0);
    }

    function buy() payable {

        //exetute if is allowed by the contract rules
        if(keccak256(buyLock)!=keccak256("close")){
            if (frozenAccount[msg.sender]) revert();                        // Check if frozen

            if (msg.sender.balance < msg.value) revert();                 // Check if the sender has enought eth to buy
            if (msg.sender.balance + msg.value < msg.sender.balance) revert(); //check for overflows

            uint dec=decimals;
            uint amount = msg.value * (buyPrice / (10**dec));                // calculates the amount

            if (amount <= 0) revert();  //check amount overflow
            if (balances[msg.sender] + amount < balances[msg.sender]) revert(); // Check for overflows
            if (balances[this] < amount) revert();            // checks if it has enough to sell

            balances[this] -= amount;                         // subtracts amount from seller's balance
            balances[msg.sender] += amount;                   // adds the amount to buyer's balance

            Transfer(this, msg.sender, amount);         //send the tokens to the sendedr
            //update status variables of the contract
            status(0,msg.value);
        }else{
          revert();
        }

    }



    function deposit() payable returns(bool success) {
        // Check for overflows;
        if (this.balance + msg.value < this.balance) revert(); // Check for overflows

        //executes event to reflect the changes
        LogDeposit(msg.sender, msg.value);

        //update contract status
         status(0, msg.value);
        return true;
    }

    function withdraw(uint value) onlyOwner {

        //send eth to owner address
        msg.sender.transfer(value);

        //executes event or register the changes
        LogWithdrawal(msg.sender, value);
        status( value,0);

    }

    function sell(uint256 amount) {

        //exetute if is allowed by the contract rules
        if(keccak256(sellLock)!=keccak256("close")){

          if (frozenAccount[msg.sender]) revert();                        // Check if frozen
          if (balances[this] + amount < balances[this]) revert(); // Check for overflows
          if (balances[msg.sender] < amount ) revert();        // checks if the sender has enough to sell

          balances[msg.sender] -= amount;                   // subtracts the amount from seller's balance
          balances[this] += amount;                         // adds the amount to owner's balance
          // Sends ether to the seller. It's important
          if (!msg.sender.send(amount * sellPrice)) {
              revert();                                         // to do this last to avoid recursion attacks
          } else {
               // executes an event reflecting on the change
               Transfer(msg.sender, this, amount);
               //update contract status
               status(amount*sellPrice,0);
          }
        }else{ revert(); }
    }

    event InvestmentOfferAdded(uint proposalID, address recipient, uint amount, string description);
    event Invested(uint proposalID, address investor, string justification);
    event ChangeOfRules(uint maxPercentageEvent, uint investmentOfferPeriodInMinutesEvent);

    struct InvestmentOffer {
        address recipient;
        uint amount;
        string description;
        uint investingDeadline;
        bool executed;
        bool investmentPassed;
        uint numberOfInvestments;
        uint currentAmount;
        bytes32 investmentHash;
        Offer[] offers;
        mapping (address => bool) invested;
    }

    struct Offer {
        bool inSupport;
        address investor;
        string justification;
    }

    /*change rules*/
    function changeInvestmentRules(
        uint maxPercentageForInvestments,
        uint minutesForInvestment
    ) onlyOwner {
        maxPercentage = maxPercentageForInvestments;
        investmentOfferPeriodInMinutes = minutesForInvestment;

        ChangeOfRules(maxPercentage, investmentOfferPeriodInMinutes);
    }

    /* Function to create a new investment offer */
    function newInvestmentOffer(
        address beneficiary,
        uint etherAmount,
        string JobDescription,
        bytes transactionBytecode
    )
        onlyOwner
        returns (uint proposalID)
    {
        uint dec=decimals;

        proposalID = investmentOffer.length++;
        InvestmentOffer storage p2 = investmentOffer[proposalID];
        p2.recipient = beneficiary;
        p2.amount = etherAmount * (10**dec);
        p2.description = JobDescription;
        p2.investmentHash = sha3(beneficiary, etherAmount, transactionBytecode);
        p2.investingDeadline = now + investmentOfferPeriodInMinutes * 1 minutes;
        p2.executed = false;
        p2.investmentPassed = false;
        p2.numberOfInvestments = 0;
        InvestmentOfferAdded(proposalID, beneficiary, etherAmount, JobDescription);
        numInvestmentOffers = proposalID+1;

        return proposalID;
    }

    /* function to check if a investment offer code matches */
    function checkInvestmentOfferCode(
        uint investmentNumber,
        address beneficiary,
        uint etherAmount,
        bytes transactionBytecode
    )
        constant
        returns (bool codeChecksOut)
    {
        InvestmentOffer storage p = investmentOffer[investmentNumber];
        return p.investmentHash == sha3(beneficiary, etherAmount, transactionBytecode);
    }

    function invest(
        uint investmentNumber,
        string justificationText,
        address target
    )
        payable
        returns (uint voteID)
    {
        uint dec=decimals;
        uint maxP=maxPercentage;

        InvestmentOffer storage p = investmentOffer[investmentNumber];                  // Get the investment Offer
        if (msg.value >= (p.amount * (maxP / 100))) revert();    // Same or less investment than maximum percent
        if (p.amount <= (p.currentAmount + msg.value)) revert(); // Check if the investment is more than total offer
        if (p.invested[msg.sender] == true) revert();                        // If has already invested, cancel
        p.invested[msg.sender] = true;                                      // Set this investor as having invested
        p.numberOfInvestments++;

        uint amount = msg.value * (buyPrice / (10**dec));                // calculates the amount

        if (amount <= 0) revert();  //check amount overflow
        if (balances[target] + amount < balances[target]) revert(); // Check for overflows
        if (this.balance + msg.value < this.balance) revert(); // Check for overflows

        p.currentAmount += msg.value;       // Increase the investment amount
        balances[target] += amount;                   // Adds the amount to target balance
        totalSupply += amount;                        // Add amount to total supply

        Transfer(0, owner, amount);                   // Send tokens to contract
        Transfer(owner, target, amount);             // Send tokens to target address

        // Create a log of this event
        Invested(investmentNumber, msg.sender, justificationText);
        //update contract status
        status(0, msg.value);
        return p.numberOfInvestments;
    }

}

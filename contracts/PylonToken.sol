pragma solidity ^0.4.11;

import "./ConvertLib.sol";
import "./Ownable.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!


contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract PylonToken is Ownable {
	/* Public variables of the token */
	string public standard = "Pylon Token - The first decentralized energy exchange platform powered by renewable energy";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

	uint256 public buyPrice;
  uint256 public sellPrice;
  string public buyLock="open";
  string public sellLock="open";
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

	mapping (address => bool) public frozenAccount;

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint256)) public allowance;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	/* This generates a public event on the blockchain that will notify clients */
  event FrozenFunds(address target, bool frozen);

  /* This notifies clients about the amount burnt */
  event Burn(address indexed _from, uint256 _value);

	function PylonToken(
		/*
    uint256 initialSupply=3000000000000000000000000,
    string tokenName = "Pylon Token",
    uint8 decimalUnits = 18,
    string tokenSymbol = "PYLNT",
		uint maxPercentage = 10,
    uint minutesForInvestment = 200,
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

	}

	function transfer(address _to, uint _value) returns(bool sufficient) {
		if (balances[msg.sender] < _value) revert();            // Check if the sender has enough
		if (balances[_to] + _value < balances[_to]) revert();   // Check for overflows
		if (frozenAccount[msg.sender]) revert();                // Check if frozen

		balances[msg.sender] -= _value;
		balances[_to] += _value;
		Transfer(msg.sender, _to, _value);

		return true;
	}

	function getBalanceInEth(address addr) returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) returns(uint) {
		return balances[addr];
	}

	/* Allow another contract to spend some tokens in your behalf */
  function approve(address _spender, uint256 _value)
      onlyOwner
      returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      return true;
  }

	/* Approve and then communicate the approved contract in a single tx */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
      onlyOwner
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

  /// @notice Remove `_value` tokens from the system irreversibly
  /// @param _value the amount of money to burn
  function burn(uint256 _value) onlyOwner returns (bool success) {
      require (balances[msg.sender] > _value);            // Check if the sender has enough
      balances[msg.sender] -= _value;                      // Subtract from the sender
      totalSupply -= _value;                                // Updates totalSupply
      Burn(msg.sender, _value);
      return true;
  }

  function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success) {
      require(balances[_from] >= _value);                // Check if the targeted balance is enough
      require(_value <= allowance[_from][msg.sender]);    // Check allowance
      balances[_from] -= _value;                         // Subtract from the targeted balance
      allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
      totalSupply -= _value;                              // Update totalSupply
      Burn(_from, _value);
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

    //set panic level and panic time
    function setPanic(uint8 panicLevelU, uint256 panicTimeU) onlyOwner {
        panicLevel=panicLevelU;
        panicTime=panicTimeU;
    }

    //Declare panic mode or not
    function panic(uint256 panicWallU) onlyOwner {
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
    event LogTransfer(address sender, address to, uint amount);

    function deposit() payable returns(bool success) {
        // Check for overflows;
        if (this.balance + msg.value < this.balance) revert(); // Check for overflows

        //executes event to reflect the changes
        LogDeposit(msg.sender, msg.value);

        return true;
    }

    function withdraw(uint value) onlyOwner {

        //send eth to owner address
        msg.sender.transfer(value);

        //executes event or register the changes
        LogWithdrawal(msg.sender, value);

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

        return p.numberOfInvestments;
    }

}

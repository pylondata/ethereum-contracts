pragma solidity ^0.4.11;

/*
    Copyright 2017, Marc Feliu

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title PylonCrowdsale Contract
/// @author Marc Feliu
/// @dev This contract will be the Pylon Token controller during the crowdsale period.
///  This contract will determine the rules during this period.
///  Final users will generally not interact directly with this contract. ETH will
///  be sent to the Pylon Token contract. The ETH is sent to this contract and from here,
///  ETH is sent to the contribution walled and Pylons are mined according to the defined
///  rules.

import "./Ownable.sol";
import './PylonToken.sol';
import './SafeMath.sol';

contract token { function transfer(address receiver, uint amount); }

contract PylonCrowdsale is Ownable {
    using SafeMath for uint256;

    address public beneficiary; // Address of ether beneficiary account
    uint public fundingGoal;    // Foundig goal in ethers
    uint public amountRaised;   // Quantity of weis investeds
    uint public deadline;       // Last moment to invest
    uint public price;          // Ether cost of each token in weis
    token public tokenReward;   // Address of Pylon Token

    uint256 public maxEtherInvestment = 760 ether; //To mofify the day when starts crowdsale
    uint256 public maxTokens = 1875000000000000000000000;

    uint256 public bonus1cap = 3000 ether; // 750.000 tokens in ethers changed last day before Crowdsale as 1,52€/token

    uint256 public startBlockBonus;

    uint256 public endBlockBonus1;
    uint256 public bonus1 = 20;

    uint256 public endBlockBonus2;
    uint256 public bonus2 = 10;

    uint256 public endBlockBonus3;
    uint256 public bonus3 = 5;

    uint256 public qnt10k = 6578000000000000000000; // 10.000 € in Pylon Token

    uint256 public qntBonus1 = 10; // Bonus for 50.000 € in ethers
    uint256 public qntBonus2 = 12; // Bonus for 60.000 € in ethers
    uint256 public qntBonus3 = 14; // Bonus for 70.000 € in ethers
    uint256 public qntBonus4 = 16; // Bonus for 80.000 € in ethers
    uint256 public qntBonus5 = 18; // Bonus for 90.000 € in ethers
    uint256 public qntBonus6 = 20; // Bonus for 100.000 € in ethers
    uint256 public qntBonus7 = 22; // Bonus for 110.000 € in ethers
    uint256 public qntBonus8 = 24; // Bonus for 120.000 € in ethers
    uint256 public qntBonus9 = 26; // Bonus for 130.000 € in ethers
    uint256 public qntBonus10 = 28; // Bonus for 140.000 € in ethers
    uint256 public qntBonus11 = 30; // Bonus for 150.000 € in ethers
    uint256 public qntBonus12 = 32; // Bonus for 160.000 € in ethers
    uint256 public qntBonus13 = 34; // Bonus for 170.000 € in ethers
    uint256 public qntBonus14 = 36; // Bonus for 180.000 € in ethers
    uint256 public qntBonus15 = 38; // Bonus for 190.000 € in ethers

    PylonToken public PYLON;

    mapping(address => uint256) public balanceOf;

    mapping (address => uint256) public investorsBought;

    bool fundingGoalReached = false; // If founding goal is reached or not

    event GoalReached(address isBeneficiary, uint256 theAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    bool crowdsaleClosed = false; // If crowdsale is closed or open

    uint256 public startBlock;
    uint256 public endBlock;

    address public destEthTeam;

    address public destTokensTeam;
    address public destTokensReserve;
    address public destTokensBounties;

    uint256 public totalNormalCollected;

    uint256 public finalizedBlock;
    uint256 public finalizedTime;

    mapping (address => uint256) public lastCallBlock;

    bool public paused;

    modifier initialized() {
        require(address(PYLON) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(getBlockNumber() >= startBlock && getBlockNumber() <= endBlock && finalizedBlock == 0 && address(PYLON) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function crowdsale() {
        paused = false;
    }

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param investor who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed investor, uint256 value, uint256 amount);

    /* data structure to hold information about campaign contributors */

    /*  at initialization, setup the owner */
    function PylonCrowdsale(
        address _ifSuccessfulSendTo,
        uint _fundingGoalInEthers,
        uint256 _startBlock,
        uint256 _endBlock,
        uint _durationInMinutes,
        uint _weiCostOfEachToken,
        token addressOfTokenUsedAsReward
    )  {

        require(address(PYLON) == 0x0);

        beneficiary = _ifSuccessfulSendTo;
        fundingGoal = _fundingGoalInEthers * 1 ether;
        deadline = now + _durationInMinutes * 1 minutes;
        price = _weiCostOfEachToken;

        require(_startBlock >= getBlockNumber());
        require(_startBlock < _endBlock);
        startBlock = _startBlock;
        endBlock = _endBlock;

        tokenReward = token(addressOfTokenUsedAsReward);
    }

    // fallback function can be used to buy tokens
    function () payable notPaused {
      buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address investor) payable notPaused initialized {
      require (!crowdsaleClosed); // Check if crowdsale is open or not
      require(investor != 0x0);  // Check the address
      require(validPurchase()); //Validate the transfer
      require(maxEtherInvestment <= msg.value); //Check if It's more than maximum to invest
      require(investorsBought[investor] >= maxTokens); // Check if the investor has more tokens than 5% of total supply
      require(amountRaised >= fundingGoal); // Check if fundingGoal is rised

      //Check if It's time for pre ICO or ICO
      if(startBlockBonus >= getBlockNumber() &&  startBlock >= getBlockNumber() && endBlockBonus3 <= getBlockNumber()){
        buyPreIco(investor);
      } else if(endBlock <= getBlockNumber()){
        buyIco(investor);
      }

    }

    function buyIco(address investor) internal {
      uint256 weiAmount = msg.value;

      // calculate token amount to be sent
      uint256 tokens = weiAmount.mul(price);

      // update state
      amountRaised += weiAmount;

      PYLON.transfer(msg.sender, tokens);

      TokenPurchase(msg.sender, investor, weiAmount, tokens);
    }

    function buyPreIco(address investor) internal {
      uint256 weiAmount = msg.value;
      uint256 bonusTokens = 0; // Bonus for dates
      uint256 bonusQnt = 0; // Bonus for quantity
      uint256 totalTokens = 0; // Total tokens with the bonus

      // calculate token amount to be sent
      uint256 tokens = weiAmount.mul(price);

      // update state
      amountRaised += weiAmount;

      if(endBlockBonus1 <= getBlockNumber()){
        //Get additional tokens for amount invested. 20% in this case
        bonusTokens = tokens.mul(percent(bonus1));
      }else if(endBlockBonus2 <= getBlockNumber()){
        //Get additional tokens for amount invested. 10% in this case
        bonusTokens = tokens.mul(percent(bonus2));
      }else{
        //Get additional tokens for amount invested. 5% in this case
        bonusTokens = tokens.mul(percent(bonus3));
      }

      if(tokens == qnt10k.mul(19) ){
        bonusQnt = tokens.mul(percent(qntBonus15));
      }else if(tokens >= qnt10k.mul(18) ){
        bonusQnt = tokens.mul(percent(qntBonus14));
      }else if(tokens >= qnt10k.mul(17) ){
        bonusQnt = tokens.mul(percent(qntBonus13));
      }else if(tokens >= qnt10k.mul(16) ){
        bonusQnt = tokens.mul(percent(qntBonus12));
      }else if(tokens >= qnt10k.mul(15) ){
        bonusQnt = tokens.mul(percent(qntBonus11));
      }else if(tokens >= qnt10k.mul(14) ){
        bonusQnt = tokens.mul(percent(qntBonus10));
      }else if(tokens >= qnt10k.mul(13) ){
        bonusQnt = tokens.mul(percent(qntBonus9));
      }else if(tokens >= qnt10k.mul(12) ){
        bonusQnt = tokens.mul(percent(qntBonus8));
      }else if(tokens >= qnt10k.mul(11) ){
        bonusQnt = tokens.mul(percent(qntBonus7));
      }else if(tokens >= qnt10k.mul(10) ){
        bonusQnt = tokens.mul(percent(qntBonus6));
      }else if(tokens >= qnt10k.mul(9) ){
        bonusQnt = tokens.mul(percent(qntBonus5));
      }else if(tokens >= qnt10k.mul(8) ){
        bonusQnt = tokens.mul(percent(qntBonus4));
      }else if(tokens >= qnt10k.mul(7) ){
        bonusQnt = tokens.mul(percent(qntBonus3));
      }else if(tokens >= qnt10k.mul(6) ){
        bonusQnt = tokens.mul(percent(qntBonus2));
      }else if(tokens >= qnt10k.mul(5) ){
        bonusQnt = tokens.mul(percent(qntBonus1));
      }

      totalTokens = tokens + bonusTokens + bonusQnt;

      PYLON.transfer(msg.sender, totalTokens);

      TokenPurchase(msg.sender, investor, weiAmount, totalTokens);

    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /* checks if the goal or time limit has been reached and ends the campaign */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function percent(uint256 p) internal returns (uint256) {
        return p.mul(10**16);
    }

    //////////
    // Constant functions
    //////////

    /// @return Total tokens issued in weis.
    function tokensIssued() public constant returns (uint256) {
        return PYLON.totalSupply();
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
      uint256 current = getBlockNumber();
      bool withinPeriod = current >= startBlock && current <= endBlock;
      bool nonZeroPurchase = msg.value != 0;
      return withinPeriod && nonZeroPurchase;
    }


    //////////
    // Testing specific methods
    //////////

    /// @notice This function is overridden by the test Mocks.
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

    /// @notice Pauses the contribution if there is any issue
    function pauseContribution() onlyOwner {
        paused = true;
    }

    /// @notice Resumes the contribution
    function resumeContribution() onlyOwner {
        paused = false;
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event NewSale(address indexed _th, uint256 _amount, uint256 _tokens, bool _guaranteed);
    event GuaranteedAddress(address indexed _th, uint256 _limit);
    event Finalized();
    event LogQuantity(uint256 _amount, string _message);
    event LogGuaranteed(address _address, uint256 _buyersLimit, uint256 _buyersBought, uint256 _buyersRemaining, string _message);
}

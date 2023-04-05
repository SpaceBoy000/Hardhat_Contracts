// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISRGRaffle {
    function generateTickets(address _account, uint256 _sgrAmount) external;
}

contract SGRRaffle is ISRGRaffle, Ownable {
    IERC20 public ISGR;
    // Constants
    uint256 constant private TICKET_PRICE = 5000000000000000000; // 5 SGR
    uint256 constant private MAX_TICKETS_PER_RAFFLE = 50;
    uint256 constant private COMPANY_FUND_PERCENTAGE = 20;
    uint256 constant private JACKPOT_PERCENTAGE = 40;
    uint256 constant private MEGA_WIN_PERCENTAGE = 25;
    uint256 constant private GOLD_RUSH_PERCENTAGE = 10;
    uint256 constant private LUCKY_POT_PERCENTAGE = 5;
    uint256 constant private MINIMUM_FUNDS_TO_PARTICIPATE = 1 ether;
    uint256 constant private RAFFLE_INTERVAL = 6 hours;

    // Variables
    uint256 public prizePool;
    uint256 public jackpot;
    uint256 public megaWin;
    uint256 public goldRush;
    uint256 public luckyPot;
    uint256 public currentRaffleId;
    address public companyWallet;
    address public oracle;
    mapping(address => bool) public blacklist;
    mapping(address => uint256) public ticketsPerAddress;
    mapping(address => uint256) public activeTicketsPerAddress;
    mapping(uint256 => mapping(uint256 => address)) public tickets;
    mapping(uint256 => uint256) public raffleIdToTotalTicketCounts;
    mapping(bytes32 => uint256) public requestIdToRaffleId;
    mapping(uint256 => uint256) public raffleIdToWinningNumber;
    mapping(uint256 => address[]) public raffleIdToWinners;
    
    uint256 public startTime;
    // Events
    event FundsAdded(uint256 amount);
    event NewRaffle(uint256 raffleId, uint256 jackpot, uint256 megaWin, uint256 goldRush, uint256 luckyPot);
    event TicketPurchased(address buyer, uint256 amount);
    event TicketSubmitted(address submitter, uint256 amount, uint256 raffleId);
    event BlacklistAdded(address account);
    event BlacklistRemoved(address account);

    constructor(address _sgr, address _oracle, address _companyWallet){
    // VRFConsumerBase(_vrfCoordinator, _oracle) {
        ISGR = IERC20(_sgr);
        oracle = _oracle;
        companyWallet = _companyWallet;
        // linkFee = _linkFee;
    }

    // Modifiers
    // modifier onlyValidPurchase() {
    //     require(msg.value >= MINIMUM_FUNDS_TO_PARTICIPATE, "Minimum amount not met.");
    //     require(!isBlacklisted(msg.sender), "You are blacklisted.");
    //     _;
    // }
    
    // modifier onlyBeforeRaffle() {
    //     require(block.timestamp < getNextRaffleTime(), "Raffle time has passed.");
    //     _;
    // }
    
    // modifier onlyAfterRaffle() {
    //     require(block.timestamp >= getNextRaffleTime(), "Raffle time has not passed yet.");
    //     _;
    // }
    
    // modifier onlyWhenNotPaused() {
    //     require(!paused, "Contract is paused.");
    //     _;
    // }

    // Functions
    function addFunds() public payable {
        require(msg.value > 0, "Value must be greater than 0.");
        prizePool += msg.value;
        emit FundsAdded(msg.value);
    }

    uint256 public tokenPrice; // using chainlink
    function generateTickets(address _account, uint256 _sgrAmount) external override {
        require(!blacklist[msg.sender], "Your address is blacklisted");
        uint256 ticketCounts = (tokenPrice * _sgrAmount) % TICKET_PRICE;
        if (ticketCounts > 0) {
            ticketsPerAddress[_account] += (ticketCounts-1);
            activeTicketsPerAddress[_account] += 1;
            uint256 curTicketNumber = raffleIdToTotalTicketCounts[currentRaffleId]++;
            tickets[currentRaffleId][curTicketNumber] = _account; // submit 1 ticket to current Raffle
        }

        pickWinner();
    }

    function putTicketToRaffleManually(uint256 _numTickets) external {
        require(!blacklist[msg.sender], "Your address is blacklisted");
        require(_numTickets <= MAX_TICKETS_PER_RAFFLE, "Maximum tickets per raffle exceeded.");
        require(activeTicketsPerAddress[msg.sender] + _numTickets <= MAX_TICKETS_PER_RAFFLE, "Maximum tickets per raffle per address");    
        require(ticketsPerAddress[msg.sender] >= _numTickets, "You don't have enough tickets");

        ticketsPerAddress[msg.sender] -= _numTickets;
        uint256 curTicketNumber = raffleIdToTotalTicketCounts[currentRaffleId];
        for (uint256 i = 0; i < _numTickets; i++) {
            curTicketNumber++;
            tickets[currentRaffleId][curTicketNumber] = msg.sender; // submit 1 ticket to current Raffle
        }

        pickWinner();
    }

    function pickWinner() public {
        if (startTime + RAFFLE_INTERVAL <= block.timestamp) {
            uint256 random1 = 0; //get from chainlink VRF
            uint256 random2 = 0;
            uint256 random3 = 0;
            uint256 random4 = 0;

            raffleIdToWinners[currentRaffleId].push(tickets[currentRaffleId][random1]);
            raffleIdToWinners[currentRaffleId].push(tickets[currentRaffleId][random2]);
            raffleIdToWinners[currentRaffleId].push(tickets[currentRaffleId][random3]);
            raffleIdToWinners[currentRaffleId].push(tickets[currentRaffleId][random4]);

            prizePool = 0;
            ISGR.transfer(companyWallet, prizePool * COMPANY_FUND_PERCENTAGE / 100);
            prizePool = prizePool - prizePool * COMPANY_FUND_PERCENTAGE / 100;
            ISGR.transfer(tickets[currentRaffleId][random1], prizePool * JACKPOT_PERCENTAGE / 100);
            ISGR.transfer(tickets[currentRaffleId][random2], prizePool * MEGA_WIN_PERCENTAGE / 100);
            ISGR.transfer(tickets[currentRaffleId][random3], prizePool * GOLD_RUSH_PERCENTAGE / 100);
            ISGR.transfer(tickets[currentRaffleId][random4], prizePool * LUCKY_POT_PERCENTAGE / 100);

            startTime = block.timestamp; // startTime += RAFFLE_INTERVAL;
            currentRaffleId++;
        }
    }

    function Run() public onlyOwner {
        startTime = block.timestamp;
    }

    function setBlacklist(address _account, bool _isBlacklist) public onlyOwner {
        blacklist[_account] = _isBlacklist;
    }

}
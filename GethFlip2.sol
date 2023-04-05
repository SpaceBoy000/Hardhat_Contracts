// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract GethFlip is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    bytes32 s_keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint32 callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 1 random value in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    // map rollers to requestIds
    mapping(uint256 => address) private s_spinner;
    // map vrf results to rollers
    mapping(address => uint256) private s_results;

    address public owner;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    uint public constant MAX_BET = 200 ether;
    uint public constant MIN_BET = 5 ether;
    uint256 public betFee = 3; // 3%
    uint256 public constant PERCENTS_DIVIDER = 100;
    mapping(address => uint256) public betting;
    bool public playGame = true;

    event FLIPCOIN(address from, uint256 amount, uint result, uint40 tm);
    event FLIPCOINED(address from, uint256 requestId, uint prediction, uint40 tm);
    event WITHDRAWFUND(address from, uint256 amount, uint40 tm);

    function flipCoin(uint _prediction) public payable returns (uint256 requestId) {
        require(playGame, "Users could bet only when game state is true");
        // require(msg.value == 5 ether || msg.value == 10 ether || msg.value == 25 ether || msg.value == 50 ether || msg.value == 100 ether || msg.value == 200 ether, "You need to input proper bet amount");
        require(_prediction == 0 || _prediction == 1, "bet value should be 0 or 1");
        
        require(2 * msg.value <= address(this).balance, "Contract balance is not enough to play game");
        require(betting[msg.sender] == 0, "You can bet only once per round");
        betting[msg.sender] = msg.value;

        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_spinner[requestId] = msg.sender;
        s_results[msg.sender] = _prediction;

        emit FLIPCOINED(msg.sender, requestId, _prediction, uint40(block.timestamp));
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 d2Value = (randomWords[0] % 2);
        address player = s_spinner[requestId];
        if (s_results[player] == d2Value) { // win
            uint256 payout = betting[player] * (PERCENTS_DIVIDER - betFee) / PERCENTS_DIVIDER * 2;
            uint256 balance = address(this).balance;
            payout = balance > payout ? payout : balance;
            payable(player).transfer(payout);
        } else { // lost

        }
        betting[player] = 0;
        
        emit FLIPCOIN(player, requestId, d2Value, uint40(block.timestamp));
    }

    function withdrawFund() public onlyOwner {
        uint amount = address(this).balance;
        payable(owner).transfer(amount);

        emit WITHDRAWFUND(msg.sender, amount, uint40(block.timestamp));
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function fundContract() public payable {
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function setBetFee(uint256 _fee) public onlyOwner {
        require(_fee >= 0 && _fee <=10, "Fee value could be between 0 and 10");
        betFee = _fee;
    }
    
    function playAndPause() public onlyOwner {
        playGame = !playGame;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
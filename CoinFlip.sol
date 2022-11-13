// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;


import "./Ownable.sol";
import "./SafeMath.sol";
import './VRFCoordinatorV2Interface.sol';
import './VRFConsumerBaseV2.sol';
import './ConfirmedOwner.sol';

contract CoinFlip is Ownable, VRFConsumerBaseV2, ConfirmedOwner {

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    bytes32 keyHash = 0x06eb0e2ea7cca202fc7c8258397a36f33d88568d2522b37aaa3b14ff6ee1b696;
    uint32 callbackGasLimit = 300000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x2eD832Ba664535e5886b75D64C46EB9a228C2610)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x2eD832Ba664535e5886b75D64C46EB9a228C2610);
        s_subscriptionId = subscriptionId;
    }

    function changeGasLimit(uint32 _newGasLimit) external onlyContractOwner {
        callbackGasLimit = _newGasLimit;
    }

    function _requestRandomWords(uint _gameNum) internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        Games[_gameNum].randomId = requestId;
        Games[_gameNum].randomIdExists = true;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(Games[_requestId].randomIdExists = true, 'Request not found');
        Games[_requestId].randomNum = _randomWords;
        Games[_requestId].randomFulfilled = true;
    }

    using SafeMath for uint;

    uint startingGame = 0;

    struct Game {
        uint gameNum;
        address player1;
        string player1Side;
        uint stake;
        address player2;
        string player2Side;
        bool filled;
        address winner;
        uint amountWon;
        string winningSide;
        uint256 randomId;
        bool randomFulfilled;
        bool randomIdExists;
        uint256[] randomNum;
        uint roll;
    }

    Game[] public Games;

    function withdrawFees() external onlyContractOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function newGame(string memory _HeadsOrTails) external payable {
        require(msg.value >= 0.00001 ether, "Too small of an amount.");
        require(uint(keccak256(abi.encodePacked(_HeadsOrTails))) == uint(keccak256(abi.encodePacked("Heads"))) || uint(keccak256(abi.encodePacked("Tails"))) == uint(keccak256(abi.encodePacked(_HeadsOrTails))), "You must pick Heads or Tails.");
        startingGame = startingGame.add(1);
        Games.push(Game(startingGame, msg.sender, _HeadsOrTails, msg.value, 0x0000000000000000000000000000000000000000, "", false, 0x0000000000000000000000000000000000000000, 0, "", 0, false, false, new uint256[](0), 0));
    }

    function fillGame(uint _gameNum) public payable {
        require(uint(msg.value) == Games[_gameNum].stake, "You must send the same amount of ETH as the other player.");
        require(Games[_gameNum].filled == false, "This game has already been filled.");
        Games[_gameNum].player2 = msg.sender;
        if (uint(keccak256(abi.encodePacked(Games[_gameNum].player1Side))) == uint(keccak256(abi.encodePacked("Heads")))) {
            Games[_gameNum].player2Side = "Tails";
        } else {
            Games[_gameNum].player2Side = "Heads";
        }
        Games[_gameNum].filled = true;
        _requestRandomWords(_gameNum);
    }

    function flipGame(uint _gameNum) external {
        require(Games[_gameNum].randomFulfilled == true);
        Games[_gameNum].roll = Games[_gameNum].randomNum[0].mod(100);
         if (Games[_gameNum].roll >= 50) {
            Games[_gameNum].winningSide = "Tails";
        } else {
            Games[_gameNum].winningSide = "Heads";
        }
        if ((uint(keccak256(abi.encodePacked(Games[_gameNum].winningSide))) == (uint(keccak256(abi.encodePacked(Games[_gameNum].player1Side)))))) {
            payable(Games[_gameNum].player1).transfer(Games[_gameNum].stake.mul(2).mul(98).div(100));
            Games[_gameNum].winner = Games[_gameNum].player2;
        } else {
            payable(Games[_gameNum].player2).transfer(Games[_gameNum].stake.mul(2).mul(98).div(100));
            Games[_gameNum].winner = Games[_gameNum].player2;
        }
        
        Games[_gameNum].amountWon = Games[_gameNum].stake.mul(2).mul(98).div(100);
    }

} 
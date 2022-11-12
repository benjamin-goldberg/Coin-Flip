// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;


import "./Ownable.sol";
import "./SafeMath.sol";
import './VRFCoordinatorV2Interface.sol';
import './VRFConsumerBaseV2.sol';
import './ConfirmedOwner.sol';

contract CoinFlip is Ownable, VRFConsumerBaseV2, ConfirmedOwner {

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        s_subscriptionId = subscriptionId;
    }

    function _requestRandomWords(uint _gameNum) internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        Games[_gameNum].randomId = requestId;
        Games[_gameNum].randomIdExists = true;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
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
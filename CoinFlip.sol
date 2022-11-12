// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;


import "./Ownable.sol";
import "./SafeMath.sol";
import "./RandomOracle.sol";

contract CoinFlip is Ownable, RandomOracle {

    using SafeMath for uint;

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
        uint256[] randomId;
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
        Games.push(Game(startingGame, msg.sender, _HeadsOrTails, msg.value, 0x0000000000000000000000000000000000000000, "", false, 0x0000000000000000000000000000000000000000, 0, "", new uint256[](0), false, false, new uint256[](0), 0));
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
        Games[_gameNum].randomId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }
    
    function flipGame(uint _gameNum) external {
        require(Games[_gameNum].randomFulfilled == true);
        Games[_gameNum].roll = Games[_gameNum].randomNum[0].mod(100);
         if (Games[_gameNum].roll >= 50) {
            Games[_gameNum].winningSide = "Tails";
        } else {
            Games[_gameNum].winningSide = "Heads";
        }
        if (Games[_gameNum].winningSide = Games[_gameNum].player1Side) {
            payable(Games[_gameNum].player1).transfer(msg.value.mul(2).mul(98).div(100));
            Games[_gameNum].winner = msg.sender;
        } else {
            payable(Games[_gameNum].player1).transfer(msg.value.mul(2).mul(98).div(100));
            Games[_gameNum].winner = Games[_gameNum].player1;
        }
        
        Games[_gameNum].amountWon = msg.value.mul(2).mul(98).div(100);
    }

} 
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;


import "./Ownable.sol";
import "./SafeMath.sol";

contract CoinFlip is Ownable {

    using SafeMath for uint;

    uint StartingGame = 0;
    uint randomNonce = 0;

    struct Game {
        uint GameNum;
        address Player1;
        string Player1Side;
        uint Stake;
        address Player2;
        string Player2Side;
        bool Filled;
        address Winner;
        uint AmountWon;
        string WinningSide;
    }

    Game[] public Games;

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function NewGame(string memory _HeadsOrTails) external payable {
        require(msg.value >= 0.00001 ether, "Too small of an amount.");
        require(uint(keccak256(abi.encodePacked(_HeadsOrTails))) == uint(keccak256(abi.encodePacked("Heads"))) || uint(keccak256(abi.encodePacked("Tails"))) == uint(keccak256(abi.encodePacked(_HeadsOrTails))), "You must pick Heads or Tails.");
        
        Games.push(Game(StartingGame, msg.sender, _HeadsOrTails, msg.value, 0x0000000000000000000000000000000000000000, "0", false, 0x0000000000000000000000000000000000000000, 0, "0"));
        StartingGame = StartingGame.add(1);
    }

    function FillGame(uint _GameNum) external payable {
        require(uint(msg.value) == Games[_GameNum].Stake, "You must send the same amount of ETH as the other player.");
        require(Games[_GameNum].Filled == false, "This game has already been filled.");
        
        Games[_GameNum].Player2 = msg.sender;
        
        if (uint(keccak256(abi.encodePacked(Games[_GameNum].Player1Side))) == uint(keccak256(abi.encodePacked("Heads")))) {
            Games[_GameNum].Player2Side = "Tails";
        } else {
            Games[_GameNum].Player2Side = "Heads";
        }
        
        randomNonce.add(1);
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce, _GameNum, Games[_GameNum].Player1))).mod(100);
        
        if (random >= 50) {
            Games[_GameNum].WinningSide = "Tails";
        } else {
            Games[_GameNum].WinningSide = "Heads";
        }
        if (uint(keccak256(abi.encodePacked(Games[_GameNum].WinningSide))) == uint(keccak256(abi.encodePacked(Games[_GameNum].Player2Side)))) {
            payable(msg.sender).transfer(msg.value.mul(2).mul(98).div(100));
            Games[_GameNum].Winner = msg.sender;
        } else {
            payable(Games[_GameNum].Player1).transfer(msg.value.mul(2).mul(98).div(100));
            Games[_GameNum].Winner = Games[_GameNum].Player1;
        }
        
        Games[_GameNum].AmountWon = msg.value.mul(2).mul(98).div(100);
        Games[_GameNum].Filled = true;
    }

} 


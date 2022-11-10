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
        uint Stake;
        address Player2;
        bool Filled;
        address Winner;
        uint AmountWon;
        uint WinningSide;
    }

    Game[] public Games;

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function NewGame() external payable {
        require(msg.value >= 0.00001 ether);
        Games.push(Game(StartingGame, msg.sender, msg.value, 0x0000000000000000000000000000000000000000, false, 0x0000000000000000000000000000000000000000, 0, 0));
        StartingGame = StartingGame.add(1);
    }

    function FillGame(uint _GameNum) external payable {
        require(uint(msg.value) == Games[_GameNum].Stake);
        require(Games[_GameNum].Filled == false);
        Games[_GameNum].Player2 = msg.sender;
        randomNonce.add(1);
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce, _GameNum, Games[_GameNum].Player1))).mod(100);
        if (random >= 50) {
            payable(address(msg.sender)).transfer(msg.value.mul(2).mul(98).div(100));
            Games[_GameNum].Winner = msg.sender;
        } else {
            payable(address(Games[_GameNum].Player1)).transfer(msg.value.mul(2).mul(98).div(100));
            Games[_GameNum].Winner = Games[_GameNum].Player1;
        }
        Games[_GameNum].AmountWon = msg.value.mul(2).mul(98).div(100);
        Games[_GameNum].Filled = true;
    }

} 


// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;


import "./Ownable.sol";
import "./SafeMath.sol";

contract CoinFlip is Ownable {

    using SafeMath for uint;

    uint StartingGame = 0;
    uint randomNonce = 0;

    struct Game {
        address Player1;
        uint GameNum;
        uint Stake;
        bool Filled;
        address Winner;
    }

    Game[] public Games;

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function NewGame(uint _stake) external payable {
        require(msg.value == _stake);
        require(msg.value >= 0.0001 ether);
        StartingGame = StartingGame.add(1);
        Games.push(Game(msg.sender, StartingGame, msg.value, false, 0x0000000000000000000000000000000000000000));
    }

    function FillGame(uint _GameNum) external payable {
        require(msg.value == Games[_GameNum].Stake);
        require(Games[_GameNum].Filled == false);
        randomNonce.add(1);
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce, _GameNum, Games[_GameNum].Player1))).mod(100);
        if (random >= 50) {
            payable(address(msg.sender)).transfer(msg.value.mul(2).mul(98).div(100));
            Games[_GameNum].Winner = msg.sender;
        } else {
            
            payable(address(Games[_GameNum].Player1)).transfer(msg.value.mul(2).mul(98).div(100));
            Games[_GameNum].Winner = Games[_GameNum].Player1;
        }
        Games[_GameNum].Filled = true;
    }

} 


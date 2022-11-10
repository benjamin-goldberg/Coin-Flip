// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;


import "./Ownable.sol";
import "./SafeMath.sol";

contract CoinFlipper is Ownable {

    using SafeMath for uint;

    uint StartingGame = 0;
    uint randomNonce = 0;

    struct BaseGame {
        address Player1;
        uint GameNum;
        uint Stake;
        uint Status;
    }

    BaseGame[] public Game;

    function NewGame(uint _stake) external payable {
        require(msg.value == _stake);
        require(msg.value >= 0.0001 ether);
        StartingGame = StartingGame.add(1);
        Game.push(BaseGame(msg.sender, StartingGame, msg.value, 0));
    }

    function FillGame(uint _GameNum) external payable {
        require(msg.value == Game[_GameNum].Stake);
        require(Game[_GameNum].Status == 0);
        randomNonce.add(1);
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce, _GameNum))) % 100;
        if (random >= 50) {
            payable(address(msg.sender)).transfer(msg.value.mul(2));
        } else {
            
            payable(address(Game[_GameNum].Player1)).transfer(msg.value.mul(2));
        }
        Game[_GameNum].Status = 1;
    }

} 


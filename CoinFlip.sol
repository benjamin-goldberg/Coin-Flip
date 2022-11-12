// SPDX-License-Identifier: UNLICENSED

//testing

pragma solidity ^0.8.13;


import "./Ownable.sol";
import "./SafeMath.sol";
import './VRFCoordinatorV2Interface.sol';
import './VRFConsumerBaseV2.sol';
import './ConfirmedOwner.sol';

contract CoinFlip is Ownable, VRFConsumerBaseV2, ConfirmedOwner {
    event RandomRequestSent(uint256 requestId, uint32 numWords);
    event RandomRequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    /**
     * HARDCODED FOR GOERLI
     * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
     */
    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function _requestRandomWords() internal returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RandomRequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RandomRequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

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

    function withdraw() external onlyContractOwner {
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
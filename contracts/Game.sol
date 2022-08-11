// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "hardhat/console.sol";
// import "./VRFConsumerBase.sol";
import "./mocks/VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Game is VRFConsumerBaseV2 {

    struct Gamer {
        uint256 number; // number from 0 to 100
        address gamerAddress; // address of gamer
        uint256 ABS; // the difference between the number of gamer and random number 
        // bool participated; // cheking in game or not user
    }

    IERC20 public token; // token for deposit in Game
    uint256 public startGame; // point in time, when game srated
    uint256 public deposit; //amount of tokens to participate in Game
    uint256 public numberOfUsers; // number of users who can participate in Game
    uint256 public id = 1; // users id
    uint256 public idOfFirstWinner;
    uint256 public _counter;
    uint256 public _numberOfWinners;
    uint256 public _count;
    bool public gameEnded;

    mapping(uint256 => Gamer) public gamers;
    mapping(address => uint256) public gamersID;
    uint256[] public winners;

    bool public randomRecived; // allowing to get random number just once
    uint256 internal fee;        // fee to get random number
    uint256 public randomResult = 101; // random number

    VRFCoordinatorV2Interface immutable COORDINATOR;

    // Your subscription ID.
    uint64 immutable subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 constant CALLBACK_GAS_LIMIT = 100000;

    // The default is 3, but you can set this higher.
    uint16 constant REQUEST_CONFIRMATIONS = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant NUM_WORDS = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    event NewGamer(address gamer, uint256 number, uint256 id);
    event GameEnded(uint256 endPoint, uint256 randomNumber);
    event Winner(address winner, uint256 winnerNumber, uint256 amount);
    event ReturnedRandomness(uint256[] randomWords);

  
//    * @notice Constructor inherits VRFConsumerBaseV2
//    *
//    * @param subscriptionId - the subscription ID that this contract uses for funding requests
//    * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
//    * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
   

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    // VRFConsumerBase(
        //     0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF coordinator
        //     0x326C977E6efc84E512bB9C30f76E30c160eD06FB LINK token address
        // ) 

    constructor (
        IERC20 _token, // address of token which you should deposit to participate
        uint256 _deposit, //amount of tokens to participate in Game
        uint256 _numberOfUsers, // maximum number of players 
        uint256 _number, // number of owner
        uint64 _subscriptionId,
        address vrfCoordinator
    )
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subscriptionId;
        address _msgSender = msg.sender;
        token = _token;
        deposit = _deposit;
        numberOfUsers = _numberOfUsers;
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 100000000000000; // 0.0001 LINK
        gamers[id].number = _number;
        gamers[id].gamerAddress = _msgSender; 
        gamersID[_msgSender] = id;
        startGame = block.timestamp;
    }

     /**
    * @notice Requests randomness
     * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
    */
    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        REQUEST_CONFIRMATIONS,
        CALLBACK_GAS_LIMIT,
        NUM_WORDS
        );
    }

    /**
    * @notice Callback function used by VRF Coordinator
    *
    * @param requestId - id of the request
    * @param randomWords - array of random results from VRF Coordinator
    */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        s_randomWords[0] = randomWords[0] % 101;
        emit ReturnedRandomness(randomWords);
    }

    /// @notice chainlink random number using V1
    // function getRandomNumber() public returns (bytes32 requestId) {
    //     require(block.timestamp - startGame >= 5 minutes, "Game is not Over");
    //     require(!randomRecived, "Random number recived");
    //     require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
    //     randomRecived = true;
    //     return requestRandomness(keyHash, fee);
    // }

    // /// @notice function from chainlink 
    // function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
    //     randomResult = randomness % 101;
    //     require(randomResult < 101, "You need to wait for random Number");
    // }

    // function getPseudorandom() private {
    //     require(!randomRecived, "Random number recived");
    //     randomRecived = true;
    //     randomResult = 69;
    // }
 
    /// @notice adding new user in game (nedded to use approve function in IERC20 token contract)
    /// @param _number number for msg.sender
    function participate(uint256 _number) public {
        address _msgSender = msg.sender;
        require(block.timestamp - startGame < 5 minutes, "Game Over");
        require(
            _number <= 100,
            "Your number should be less than 100"
        );
        require(gamers[gamersID[_msgSender]].gamerAddress != _msgSender, "You are already in game");

        require(calculateParticipants(), "Limit of users");
        ++id;
        gamersID[_msgSender] = id;
        gamers[id].number = _number;
        gamers[id].gamerAddress = _msgSender;
        token.transferFrom(_msgSender, address(this), deposit);

        emit NewGamer(_msgSender, _number, id);
    }

    /// @notice getting winners
    function getWinner() public {
        require(randomRecived, "You need to get random number");
        // randomRecived == true
        // ? require(randomResult < 101, "You need to get random Number")
        // : getPseudorandom();
        require(block.timestamp - startGame >= 5 minutes, "Game is not Over");
        require(!gameEnded, "Game ended, tokens transfered to winners");

        _numberOfWinners = getNumberOfWinners();
        _counter = abs(1);

        for (uint256 i = 0; i <= id;) { // getting the nearest number to random number
            gamers[i].ABS = abs(i);
            if (_counter > gamers[i].ABS){
                _counter = gamers[i].ABS;
                idOfFirstWinner = i;
                unchecked { ++i; } // lower gas
            }
        }

        idOfFirstWinner > 0
        ? idOfFirstWinner = idOfFirstWinner
        : idOfFirstWinner = 1;

        for (uint256 j = 0; j < _numberOfWinners && _numberOfWinners >= _count;) {
            for (uint256 i = 0; i <= id;) { // getting array of wiiners 
                if (_counter == gamers[i].ABS) {
                    _count++;
                    // _numberOfWinners > 0 ? _numberOfWinners-- : _numberOfWinners;
                    winners.push(i);
                    idOfFirstWinner = i;
                    unchecked { ++i; } // lower gas
                } 
            }
            _counter = gamers[idOfFirstWinner].ABS;
            for (uint256 i = 0; i <= id;) { // getting array of wiiners 
                if (_counter > gamers[i].ABS && _counter != gamers[idOfFirstWinner].ABS){
                    _counter = gamers[i].ABS;
                    unchecked { ++i; } // lower gas
                } 
            }
            unchecked { ++j; } // lower gas
        }
        
        // _count < _numberOfWinners
        //     ? getMoreWinners(_count)
        //     : transferWinnerAmount();
            
        // transferWinnerAmount(); 

        uint256 _winnerAmount = calculateWinnerAmount();
        uint256 length = winners.length; // lower gas
        for (uint256 i = 0; i < length;) { // transfering winners amount of tokens
            token.transfer(gamers[winners[i]].gamerAddress, _winnerAmount);
            unchecked { i++; } // lower gas
            emit Winner(gamers[winners[i]].gamerAddress, gamers[winners[i]].number, _winnerAmount);
        }

        gameEnded = true;
        emit GameEnded(block.timestamp, randomResult);
    }

    // function transferWinnerAmount() private {
    //     uint256 _winnerAmount = calculateWinnerAmount();
    //     for (uint256 i = 0; i < winners.length; i++) { // transfering winners amount of tokens
    //         token.transfer(gamers[winners[i]].gamerAddress, _winnerAmount);
    //         emit Winner(gamers[winners[i]].gamerAddress, gamers[winners[i]].number, _winnerAmount);
    //     }
    // }

    /// @notice checking amount of users in game
    function calculateParticipants() private view returns(bool) {
        return numberOfUsers > 0 
            ? numberOfUsers > id ? true : false 
            : true;
    }

    /// @notice gets amount of winners (30% from gamers)
    function getNumberOfWinners() private returns(uint256){
        _numberOfWinners = id * 10 / 30;
        return _numberOfWinners > 0 ? _numberOfWinners : 1;
    }

    /// @notice calculating amount of tokens to winners
    function calculateWinnerAmount() private view returns(uint256) {
        return token.balanceOf(address(this)) / winners.length;
    }

    /// @notice calculating the difference between the number of gamer and random number
    function abs(uint256 i) private view returns(uint256) {
        return gamers[i].number >= randomResult
            ? gamers[i].number - randomResult
            : randomResult - gamers[i].number;
    }
}
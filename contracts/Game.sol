// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "hardhat/console.sol";
// import "./VRFConsumerBase.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Game {//is VRFConsumerBase {

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

    mapping(uint256 => Gamer) public gamers;
    mapping(address => uint256) public gamersID;
    uint256[] public winners;

    bool public randomRecived; // allowing to get random number just once
    bytes32 internal keyHash; // identifies which Chainlink oracle to use
    uint256 internal fee;        // fee to get random number
    uint256 public randomResult = 101; // random number

    event NewGamer(address gamer, uint256 number, uint256 id);
    event GameEnded(uint256 endPoint, uint256 randomNumber);
    event Winner(address winner, uint256 winnerNumber, uint256 amount);

    constructor (
        IERC20 _token, // address of token which you should deposit to participate
        uint256 _deposit, //amount of tokens to participate in Game
        uint256 _numberOfUsers, // maximum number of players 
        uint256 _number // number of owner
    )
        // VRFConsumerBase(
        //     0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF coordinator
        //     0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK token address
        // ) 
    {
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

    // /// @notice function from chainlink
    // function getRandomNumber() public returns (bytes32 requestId) {
    //     console.log(1);
    //     require(!randomRecived, "Random number recived");
    //     console.log(4);
    //     require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
    //     console.log(2);
    //     randomRecived = true;
    //     console.log(3);
    //     return requestRandomness(keyHash, fee);
    // }

    // /// @notice function from chainlink 
    // function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
    //     randomResult = randomness % 101;
    //     require(randomResult < 101, "You need to wait for random Number");
    // }

    function getPseudorandom() private {
        require(!randomRecived, "Random number recived");
        randomRecived = true;
        randomResult = 69;
    }
 
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
        id++;
        gamersID[_msgSender] = id;
        gamers[id].number = _number;
        gamers[id].gamerAddress = _msgSender;
        token.transferFrom(_msgSender, address(this), deposit);

        emit NewGamer(_msgSender, _number, id);
    }

    /// @notice getting winners
    function getWinner() public {
        randomRecived == true
        ? require(randomResult < 101, "You need to get random Number")
        : getPseudorandom(); //getRandomNumber()
        require(block.timestamp - startGame >= 5 minutes, "Game is not Over");

        _numberOfWinners = getNumberOfWinners();
        _counter = abs(1);

        for (uint256 i = 0; i <= id; i++) { // getting the nearest number to random number
            gamers[i].ABS = abs(i);
            if (_counter > gamers[i].ABS){
                _counter = gamers[i].ABS;
                idOfFirstWinner = i;
            }
        }

        idOfFirstWinner > 0
        ? idOfFirstWinner = idOfFirstWinner
        : idOfFirstWinner = 1;

        for (uint256 j = 0; j < _numberOfWinners && _numberOfWinners >= _count; j++) {
            for (uint256 i = 0; i <= id; i++) { // getting array of wiiners 
                if (_counter == gamers[i].ABS) {
                    _count++;
                    // _numberOfWinners > 0 ? _numberOfWinners-- : _numberOfWinners;
                    winners.push(i);
                    idOfFirstWinner = i;
                } 
            }
            _counter = gamers[idOfFirstWinner].ABS;
            for (uint256 i = 0; i <= id; i++) { // getting array of wiiners 
                if (_counter > gamers[i].ABS && _counter != gamers[idOfFirstWinner].ABS){
                    _counter = gamers[i].ABS;
                } 
            }
        }
        
        // _count < _numberOfWinners
        //     ? getMoreWinners(_count)
        //     : transferWinnerAmount();
            
        // transferWinnerAmount(); 

        uint256 _winnerAmount = calculateWinnerAmount();
        for (uint256 i = 0; i < winners.length; i++) { // transfering winners amount of tokens
            token.transfer(gamers[winners[i]].gamerAddress, _winnerAmount);
            emit Winner(gamers[winners[i]].gamerAddress, gamers[winners[i]].number, _winnerAmount);
        }

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
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import "./Game.sol";

contract GameFactory {

    struct Games{
        IERC20 token;
        uint256 deposit;
        uint256 number;
        uint256 numberOfUsers;
        address gameOwner;
        address gameAddress;
    }

    address public owner;
    uint64 public subscriptionId;
    address public vrfCoordinator;
    
    event GameStarted(IERC20 token, uint256 deposit, uint256 number, uint256 numberOfUsers, address owner, address gameAddress);

    mapping(address => Games) public games;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor (
        
    ) {
        owner = msg.sender;
        subscriptionId = 1377;
        vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    }

    /// @notice creating new game
    /// @param _token IERC20 token for participate in game
    /// @param _deposit amount of deposit in _token for participate in game
    /// @param _numberOfUsers maximum number of players should be equals ZERO if you don't need a limit
    /// @param _number number which selected by owner of game
    function startGame(IERC20 _token, uint256 _deposit,uint256 _numberOfUsers, uint256 _number) public {
        address _msgSender = msg.sender;

        require(address(_token) != address(0), "Wrong token address");
        require(_deposit != 0, "Deposit shoul be more than ZERO");
        require (
            games[_msgSender].gameOwner == address(0),
            "You can create just one game for one address"
        );
        require(
            _number <= 100,
            "Your number should be less or equals to 100"
        );

        Game game = new Game(_token, _deposit, _numberOfUsers, _number, subscriptionId, vrfCoordinator);
        games[_msgSender] = Games({
            token: _token,
            deposit: _deposit,
            number: _number,
            numberOfUsers: _numberOfUsers,
            gameOwner: _msgSender,
            gameAddress: address(game)
        });

        _token.transferFrom(_msgSender, address(game), _deposit);

        emit GameStarted(_token, _deposit, _number, _numberOfUsers, _msgSender, address(game));
    }

    function changeSubscriptionId (uint64 _subscriptionId) public onlyOwner {
        subscriptionId = _subscriptionId;
    }

    function chamgeVrfCoordinator (address _vrfCoordinator) public onlyOwner {
        vrfCoordinator = _vrfCoordinator;
    }
}
## ***`Game Voting using chainlink random` contract***

## ***`Factory` contract***
1. `Factory` allow to all users to create game once
```solidity
   function startGame(IERC20 _token, uint256 _deposit,uint256 _numberOfUsers, uint256 _number)
```
 `_token` - IERC20 token for participate in game
 `_deposit` - amount of deposit in _token for participate in game
 `_numberOfUsers` - maximum number of players should be equals ZERO if you don't need a limit
 `_number` - number which selected by owner of game
after using this function your game is started, and you have address of new contract game 

## ***How to participate in `Game`***
1. `Game` allow to all users to participate, you should deposit tokens th same to `token` with the amount equals to `deposit`
```solidity
   function participate(uint256 _number)
```
 you have to write `_number` your number should be 0 <= `_number` <= 100
 you can participate once, you have 5 minutes from creating game point in time
 in each game creator can write limit of players

2. When game ended every user can write this function, which will get winners and transfer all tokens to winners
```solidity
   function getWinner()
```
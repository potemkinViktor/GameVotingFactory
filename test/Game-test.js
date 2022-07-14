const { inputToConfig } = require("@ethereum-waffle/compiler");
const { BigNumber, utils } = require("ethers");
const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")


function ether(eth) {
    let weiAmount = ethers.utils.parseEther(eth)
    return weiAmount;
}

async function getLatestBlockTimestamp() {
    return (await ethers.provider.getBlock("latest")).timestamp || 0
}

async function skipTimeTo(timestamp) {
    await network.provider.send("evm_setNextBlockTimestamp", [timestamp])
    await network.provider.send("evm_mine")
}

async function getUserInfo(address, uintNumber, uint) {
    let gamersUser = await game.gamers(uint);
    let gamersID = await game.gamersID(address);

    expect (await game.id()).to.equal(uint);

    expect (gamersUser[0]).to.equal(uintNumber);
    expect (gamersUser[1]).to.equal(address);
    expect (gamersUser[2]).to.equal(0);

    expect (gamersID).to.equal(uint);
}

async function getUsersWinner() {
    expect (await game.connect(user1).participate(46));
    await getUserInfo(user1.address, 46, 2);
    expect (await game.connect(user2).participate(55)).to.ok;
    await getUserInfo(user2.address, 55, 3);
}

const FIVE_MIN = 301; // = 5 * 60 
// const PERCANTAGE = ether("11.3");
const DEPOSIT = ether("0.5");
const NUMBER_OF_USERS = 5;
const NUMBER = 46;

!developmentChains.includes(network.name)
  ? describe.skip : describe ("Game", async function () {
    let owner, user1, user2;

    // let randomNumberConsumer, linkToken, vrfCoordinatorMock

//       beforeEach(async () => {
//         await deployments.fixture(["mocks", "vrf"])
//         linkToken = await ethers.getContract("LinkToken")
//         vrfCoordinatorMock = await ethers.getContract("VRFCoordinatorMock")
//         linkTokenAddress = linkToken.address
//         additionalMessage = " --linkaddress " + linkTokenAddress

//         randomNumberConsumer = await ethers.getContract("RandomNumberConsumer")

//         await hre.run("fund-link", {
//           contract: randomNumberConsumer.address,
//           linkaddress: linkTokenAddress,

    beforeEach ("Deploy the contract", async function () {
        
        [owner, user1, user2, user3] = await ethers.getSigners();
        // linkToken = await ethers.getContractAt("LinkToken");
        // randomNumberConsumer = await ethers.getContractFactory("RandomNumberConsumer");
        
        Mock = await ethers.getContractFactory("MockERC20");
        mock = await Mock.deploy(113);
        await mock.deployed();

        GameFactory = await ethers.getContractFactory("GameFactory");
        gameFactory = await GameFactory.deploy();
        await gameFactory.deployed();
        
        Game = await ethers.getContractFactory("Game");
        game = await Game.deploy(
            mock.address,
            ether("0.5"),
            3,
            57,
        );
        await game.deployed();
        expect (await mock.transfer(game.address, ether("0.5"))).to.ok;
        expect (await mock.balanceOf(game.address)).to.equal(ether("0.5"));
        // linkToken = await ethers.getContractFactory("LinkToken")
        // let linkTokenAddress = mock.address;
        // additionalMessage = " --linkaddress " + linkTokenAddress;

        // VrfCoordinatorMock = await ethers.getContractFactory("VRFCoordinatorMock");
        // vrfCoordinatorMock = await VrfCoordinatorMock.deploy(linkTokenAddress);
        // await vrfCoordinatorMock.deployed();
        
        // await hre.run("fund-link", {
        //     contract: game.address,
        //     linkaddress: linkTokenAddress,
        //   }); randomRecived randomResult idOfFirstWinner

        await getUserInfo(owner.address, 57, 1);

        expect (await game._count()).to.equal(0);
        expect (await game._numberOfWinners()).to.equal(0);
        expect (await game.idOfFirstWinner()).to.equal(0);
        expect (await game._counter()).to.equal(0);
        expect (await game.token()).to.equal(mock.address);
        expect (await game.randomRecived()).to.equal(false);
        expect (await game.randomResult()).to.equal(101);
        expect (await game.numberOfUsers()).to.equal(3);
        expect (await game.startGame()).to.equal(await getLatestBlockTimestamp() - 1); //- 1

        expect (await mock.transfer(user1.address, ether("1"))).to.ok;
        expect (await mock.transfer(user2.address, ether("0.5"))).to.ok;
        expect (await mock.transfer(user3.address, ether("0.5"))).to.ok;
        expect (await mock.connect(user1).approve(game.address, ether("0.5"))).to.ok;
        expect (await mock.connect(user2).approve(game.address, ether("0.5"))).to.ok;
        expect (await mock.connect(user3).approve(game.address, ether("0.5"))).to.ok;

        expect (await mock.transfer(owner.address, ether("0.5"))).to.ok;
        expect (await mock.connect(owner).approve(gameFactory.address, ether("0.5"))).to.ok;
    });
    
    describe ("GameFactory", async function (){
        it("startGame", async function (){
            await expect (gameFactory.connect(owner).startGame(mock.address, ether("0.5"), 3, 101)).to.be.revertedWith("Your number should be less or equals to 100");
            await expect (gameFactory.connect(owner).startGame(mock.address, ether("0"), 3, 57)).to.be.revertedWith("Deposit shoul be more than ZERO");
            // await expect (gameFactory.connect(owner).startGame("0", ether("0.5"), 3, 57)).to.be.revertedWith("Wrong token address");
            expect (await gameFactory.connect(owner).startGame(mock.address, ether("0.5"), 0, 57));
            await expect (gameFactory.connect(owner).startGame(mock.address, ether("0.5"), 0, 57)).to.be.revertedWith("You can create just one game for one address");

            let games = await gameFactory.games(owner.address);
            expect (games[0]).to.equal(mock.address);
            expect (games[1]).to.equal(ether("0.5"));
            expect (games[2]).to.equal(57);
            expect (games[3]).to.equal(0);
            expect (games[4]).to.equal(owner.address);
          });
    });

    describe ("Random number", async function (){
        it("Should successfully request a random number", async function (){
            // await expect (game.getRandomNumber()).to.be.revertedWith("Not enough LINK in contract");
            // const transaction = await game.getRandomNumber();
            // const transactionReceipt = await transaction.wait(1);
            // const requestId = transactionReceipt.events[0].topics[1];
            // console.log("requestId: ", requestId);
            // expect(requestId).to.not.be.null;
          });
    
        //   it("Should successfully request a random number and get a result", async function (){
        //     const transaction = await randomNumberConsumer.getRandomNumber();
        //     const transactionReceipt = await transaction.wait(1);
        //     const requestId = transactionReceipt.events[0].topics[1];
        //     const randomValue = 777;
        //     await vrfCoordinatorMock.callBackWithRandomness(
        //       requestId,
        //       randomValue,
        //       randomNumberConsumer.address
        //     );
        //     assert.equal((await randomNumberConsumer.randomResult()).toString(), randomValue);
        //   });
    });

    describe ("Game", async function (){

        it("REQUIRE", async function () {
            await expect (game.connect(user1).participate(101)).to.be.revertedWith("Your number should be less than 100");

            await skipTimeTo(await getLatestBlockTimestamp() + FIVE_MIN);
            await expect (game.connect(user2).participate(55)).to.be.revertedWith("Game Over");
        });

        it ("participate and getting winner", async function (){
            expect (await mock.balanceOf(user1.address)).to.equal(ether("1"));
            expect (await mock.balanceOf(user2.address)).to.equal(ether("0.5"));
            
            expect (await game.id()).to.equal(1);

            expect (await game.connect(user1).participate(59))
                .to.emit(game, 'NewGamer')
                .withArgs(user1.address, 59, 2);

            await getUserInfo(user1.address, 59, 2);
            expect (await game.id()).to.equal(2);
            expect (await mock.balanceOf(user1.address)).to.equal(ether("0.5"));

            await expect (game.connect(user1).participate(100)).to.be.revertedWith("You are already in game");
            // expect (game._msgSender()).to.equal(user1.address);
            // expect (await game._msgSender()).to.equal(user1.address);

            expect (await game.connect(user2).participate(59)).to.ok
                .to.emit(game, 'NewGamer')
                .withArgs(user2.address, 59, 3);

            await getUserInfo(user2.address, 59, 3);
            expect (await game.id()).to.equal(3);
            expect (await mock.balanceOf(user2.address)).to.equal(ether("0"));

            await expect (game.connect(user3).participate(99)).to.be.revertedWith("Limit of users");

            expect (await game._numberOfWinners()).to.equal(0);
            expect (await game._counter()).to.equal(0);
            expect (await game.idOfFirstWinner()).to.equal(0);
            expect (await game.randomRecived()).to.equal(false);
            expect (await game.gameEnded()).to.equal(false);
            await expect (game.getWinner()).to.be.revertedWith("Game is not Over");
            await skipTimeTo(await getLatestBlockTimestamp() + FIVE_MIN);

            await expect (game.getWinner()).to.ok;
            expect (await game._counter()).to.equal(10);
            // expect (await game.idOfFirstWinner()).to.equal(2);
            expect (await game._count()).to.equal(2);
            expect (await game._numberOfWinners()).to.equal(1);
            let winner1 = await game.winners(0);
            expect (winner1).to.equal(2);
            let winner2 = await game.winners(1);
            expect (winner2).to.equal(3);
        
            expect (await mock.balanceOf(user1.address)).to.equal(ether("1.25"));
            expect (await mock.balanceOf(user2.address)).to.equal(ether("0.75"));
            expect (await game.gameEnded()).to.equal(true);
            await expect (game.getWinner()).to.be.revertedWith("Game ended, tokens transfered to winners");
        });
        
    });

    
});
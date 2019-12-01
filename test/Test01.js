const dogSystem = artifacts.require('./DogToken.sol')
const erc721 = artifacts.require('./ERC721.sol')

let tryCatch = require("./exceptions.js").tryCatch;
let errTypes = require("./exceptions.js").errTypes;

contract('Creating dog contract', accounts => {

    beforeEach('setup contracts for each test', async function() {
        erc = await erc721.new({from : accounts[0]})
        dog = await dogSystem.new(erc.address)

        await erc.approve(dog.address, 1, {from: accounts[0]})
        await dog.deposit(1, accounts[0], {from: accounts[1]})

        await erc.approve(dog.address, 2, {from: accounts[0]})
        await dog.deposit(2, accounts[0], {from: accounts[2]})
    })

    it('test the fixed price sale function', async function() {

        await dog.putToSale(1, 1000, {from : accounts[1]})
        retrieve = await dog.listAnimals(1)
        assert.equal(retrieve.salePrice, 1000, "sale price is not 1000")

        await dog.creditBalance(2000, accounts[2])
        await dog.buyFixedPrice(1, {from :accounts[2]})
        /*Check balance after trade*/
        check = await dog.balanceOf(accounts[1])
        assert.equal(1000, check, "balance of seller has not been incremented")
        /*Check change of owner*/
        own = await dog.ownerOf(1)
        assert.equal(own, accounts[2], "change of owner has not been operated")
    })

    it('test auction function', async function() {
        await dog.createAuction(1, 2000, 2, {from : accounts[1]})
        res = await dog.listAuctions(0)
        assert.equal(res.open, true, "auction is closed")
        assert.equal(res.animalId, 1, "wrong animal linked to auction")

        await dog.creditBalance(5000, accounts[3])
        res = await dog.listAuctions(0)
        
        await dog.bidOnAuction(0, 2300, {from: accounts[3]})
        res = await dog.listAuctions(0)
        assert.equal(res.lastBuyer, accounts[3], "auction last bidder has not been updated")
        assert.equal(res.currentPrice, 2300, "auction bid has not been updated")
        res = await dog.balanceOf(accounts[3])
        assert.equal(res, 2700, "last bidder has not been withdrawned")

        await dog.creditBalance(10000, accounts[4])
        await dog.bidOnAuction(0, 2500, {from : accounts[4]})
        res = await dog.balanceOf(accounts[4])
        res2 = await dog.balanceOf(accounts[3])
        assert.equal(res, 7500, "last bidder has not been withdrawned")
        assert.equal(res2, 5000, "precedent bidder has not been reimbursed")

        res = await dog.listAuctions(0)
        assert.equal(res.currentPrice, 2500, "current price not updated")
    })

    it('test the fight function', async function() {
        await dog.creditBalance(1000, accounts[1])
        await dog.creditBalance(1000, accounts[2])

        await dog.findFight(1, {from: accounts[1]})
        await dog.findFight(2, {from: accounts[2]})

        survivor = await dog.fight(1, 2, 700, {from: accounts[1]})

    })

    it('test the breed function', async function() {
        await dog.registerBreeder({from: accounts[1]})
        await dog.registerBreeder({from: accounts[2]})

        await dog.wantsToBreed(1, {from: accounts[1]})
        await dog.wantsToBreed(2, {from: accounts[2]})

        await dog.breed(1, 2, accounts[1], {from: accounts[1]})

        res = await dog.listAnimals(5)
        assert.equal(res.owner, accounts[1])
    })
})



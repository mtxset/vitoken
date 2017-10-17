const ViMarket = artifacts.require("ViMarket.sol")

import { expectThrow } from "./helpers/index"
import { expect } from "chai"

let vi = null;
const decimals = 2;
const viTotalSupply = 9.999 * 10**(9+2); // 9.999 Billions
const rate = 322;

var king; // will use this as owner
var queen;
var jack;
var ace;
var joker;
var magpie;

// Helper functions
function ReturnEventAndArgs(returnVal)
{
    return { eventName: returnVal.logs[0].event, 
             eventArgs: returnVal.logs[0].args.action,
             raw: returnVal }
}
// -- Helper functions

contract("Vitoken", (accounts)=> 
{
    before(async()=>
    {
        king = accounts[0];
        queen = accounts[1];
        jack = accounts[2];
        ace = accounts[3];
        joker = accounts[4];
        magpie = accounts[5];
    })
 
    describe("Initialize", async()=>
    {
        describe("Correct Init", async()=>
        {
            it("It should initialize", async()=>
            {
                vi = await ViMarket.new({from: king});

                expect(await vi.owner(), 
                    "Owners should match")
                    .to.equal(king);

                expect((await vi.totalSupply()).toNumber(),
                    "Total supply should match")
                    .to.equal(viTotalSupply);

                expect((await vi.balanceOf(king)).toNumber(),
                    "Balance should equal to initial supply")
                    .to.equal(viTotalSupply);
            })
        })
    })

    describe("Function: transferOwnership(address newOwner) ", async()=>
    {
        it("Should correctly transfer ownership", async()=>
        {
            vi = await Vitoken.new({from: king});

            // Checking current owner
            expect(await vi.owner(), 
                "Owners should match")
                .to.equal(king);

            let r = ReturnEventAndArgs(await vi.transferOwnership(queen, {from:king}));
            
            expect(r.eventName, 
                "Event EventOwnerTransfered was not fired")
                .to.be.equal("EventOwnerTransfered");

            expect(await vi.owner(), 
                "Owners should match")
                .to.equal(queen);
        })

        it("Should not trasnfer ownership (not owner transfers)", async()=>
        {
            vi = await Vitoken.new({from: king});

            expect(await vi.owner(), 
                "Owners should match")
                .to.equal(king);

            expect(await expectThrow(vi.transferOwnership(jack, {from:queen})),
                "Should throw")
                .to.be.true;
        })

        it("Should not transfer ownership (passing 0 address)", async()=>
        {
            vi = await Vitoken.new({from: king});

            expect(await vi.owner(), 
                "Owners should match")
                .to.equal(king);

            expect(await expectThrow(vi.transferOwnership(0, {from:king})),
                "Should throw")
                .to.be.true;
        })
    })

    describe("BuyTokens(address beneficiary)", async()=>
    {
        beforeEach(async()=>
        {
            vi = await Vitoken.new({from: king});
        })

        it("Should correctly buy tokens", async()=>
        {
            let valueInEther = 10;
            let valueInWei = web3.toWei(valueInEther, "ether");
            let rate = (await vi.rate.call()).toNumber();

            let expectedTokenAmount = +rate * +valueInEther;
            let balanceOfContract = await vi.balanceOf(vi.address);
            let balanceOfBeneficiary = await vi.balanceOf(queen);

            // Check if balances are correct
            // buy tokens
            let r = ReturnEventAndArgs(
                await vi.BuyTokens(queen, {from:king, value:valueInWei}));
            
            // Checking if event fired
            expect(r.eventName, 
                "Event EventOwnerTransfered was not fired")
                .to.be.equal("EventTokenPurchase");

            let purchaser = r.raw.logs[0].args["purchaser"];
            let beneficiary = r.raw.logs[0].args["beneficiary"];
            let tokens = r.raw.logs[0].args["tokens"].toNumber();
            let buyRate = r.raw.logs[0].args["buyRate"].toNumber();

            // Checking event passed parameters
            expect(purchaser, "Purchaser is incorrect")
                .to.equal(king);

            expect(beneficiary, "Beneficiary is incorrect")
                .to.equal(queen);

            expect(tokens, "Tokens are incorrect")
                .to.equal(expectedTokenAmount);

            expect(buyRate, "BuyRate is incorrect")
                .to.equal(rate);

            // Checking actual results
            expect((await vi.balanceOf(vi.address)).toNumber(), //tokens are held in contract address
                "Balance did not decrease for sender") 
                .to.equal(+balanceOfContract - +tokens);
            
            expect((await vi.balanceOf(queen)).toNumber(), // tokens of beneficiary
                "Balance did not increase for beneficiary")
                .to.equal(+balanceOfBeneficiary + +tokens);
            
        })

        describe("Should not buy tokens", async()=>
        {
            var valueInEther = 10;
            var valueInWei = web3.toWei(valueInEther, "ether");

            it("Passing 0 for beneficiary", async()=>
            {
                expect(await expectThrow(vi.BuyTokens(0, {from:king, value:valueInWei})),
                    "Should throw")
                    .to.be.true;
            })

            it("Passing owner for beneficiary", async()=>
            {
                expect(await expectThrow(vi.BuyTokens(king, {from:king, value:valueInWei})),
                    "Should throw")
                    .to.be.true;
            })

            it("Passing 0 for value (sending 0 ether)", async()=>
            {
                expect(await expectThrow(vi.BuyTokens(queen, {from:king, value:0})),
                    "Should throw")
                    .to.be.true;
            })
        })
    })
})
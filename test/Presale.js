const QuickQuid = artifacts.require("QuickQuid");
const Presale = artifacts.require("Presale");

contract("Presale", accounts => {
    let quickQuidInstance;
    let presaleInstance;
    const owner = accounts[0];
    const buyer = accounts[1];
    const tokenPriceETH = 6 *10**12

    before(async () => {
        quickQuidInstance = await QuickQuid.deployed();
        const startTime = Math.floor(Date.now() / 1000); // current time in seconds
        presaleInstance = await Presale.new(quickQuidInstance.address, startTime);

        // Mint tokens and approve Presale contract to spend them
        const totalTokens = web3.utils.toWei("40", "ether"); // 40 million tokens
        await quickQuidInstance.mint(owner, totalTokens);
        await quickQuidInstance.approve(presaleInstance.address, totalTokens);

        // Check balance and allowance before transfer
        const balance = await quickQuidInstance.balanceOf(owner);
        const allowance = await quickQuidInstance.allowance(owner, presaleInstance.address);
        console.log(`Balance: ${balance}, Allowance: ${allowance}`);

        // Transfer tokens to Presale contract
        await quickQuidInstance.transfer(presaleInstance.address, totalTokens);
    });

    it("should have correct token set", async () => {
        const token = await presaleInstance.token();
        assert.equal(token, quickQuidInstance.address);
    });

    it("should correctly receive ETH when buying tokens", async () => {
        const initialBalance = await web3.eth.getBalance(presaleInstance.address);
        const amountToBuy = web3.utils.toWei('0.06', 'ether'); // 1 ETH

        await presaleInstance.buyTokens({ from: buyer, value: amountToBuy });

        const finalBalance = await web3.eth.getBalance(presaleInstance.address);
        assert.equal(finalBalance, initialBalance + amountToBuy, "ETH amount was not correctly received");
    });

    it("should not allow buying tokens when sale is paused", async () => {
        await presaleInstance.pauseSale({ from: owner });
        const amountToBuy = web3.utils.toWei("0.06", "ether");
        try {
            await presaleInstance.buyTokens({ from: buyer, value: amountToBuy });
            assert.fail("Expected revert not received");
        } catch (error) {
            const revertFound = error.message.search('revert') >= 0;
            assert(revertFound, `Expected "revert", got ${error} instead`);
        }
    });

    it("should increase the round after all tokens in a round are sold", async () => {
        const initialRound = await presaleInstance.currentRound();
        const tokensPerRound = await presaleInstance.tokensPerRound();
        const amountToBuy = tokensPerRound * tokenPriceETH; // enough to buy all tokens in a round

        await presaleInstance.buyTokens({ from: buyer, value: amountToBuy });

        const finalRound = await presaleInstance.currentRound();
        assert.equal(finalRound.valueOf(), initialRound.valueOf() + 1, "Round did not increase");
    });

    it("should not allow buying tokens after all rounds are finished", async () => {
        const totalRounds = await presaleInstance.TOTAL_ROUNDS();
        const tokensPerRound = await presaleInstance.tokensPerRound();
        const amountToBuy = tokensPerRound * tokenPriceETH; // enough to buy all tokens in a round
        // Buy all tokens in all rounds
        for (let i = 0; i < totalRounds; i++) {
            await presaleInstance.buyTokens({ from: buyer, value: amountToBuy });
        }

        try {
            // Try to buy more tokens
            await presaleInstance.buyTokens({ from: buyer, value: amountToBuy });
            assert.fail("Expected revert not received");
        } catch (error) {
            const revertFound = error.message.search('revert') >= 0;
            assert(revertFound, `Expected "revert", got ${error} instead`);
        }
    });

});
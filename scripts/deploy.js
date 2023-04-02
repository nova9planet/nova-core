const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    
    console.log("Account balance:", (await deployer.getBalance()).toString());
    // get nonce
    const nonce = await deployer.getTransactionCount();
    console.log("Account nonce:", nonce);

    const overrides = {
        nonce: nonce,
        gasLimit: 30000000,
    };

    const MAX_SUPPLY = 10000;
    const PRE_SALE_PRICE = ethers.utils.parseEther("0.001");
    const AFTER_PRICE = ethers.utils.parseEther("0.002");
    const PRE_SALE_MINT_BLOCKNUMBER = 7831810;
    const AFTER_MINT_BLOCKNUMBER = 7835000;
    const PRE_SALE_MAX_MINT = 2000;
    const TEAM_SUPPLY = 1000;

    const NovaToken = await ethers.getContractFactory("NovaToken");
    const novaToken = await NovaToken.deploy(MAX_SUPPLY, PRE_SALE_PRICE, AFTER_PRICE, PRE_SALE_MINT_BLOCKNUMBER, AFTER_MINT_BLOCKNUMBER, PRE_SALE_MAX_MINT, overrides);
    await novaToken.deployed();

    await novaToken.mintTeamSupply(TEAM_SUPPLY);

    console.log("novaToken address:", novaToken.address);
}

main().catch((error) => {
    console.log(error);
    process.exitCode = 1;
});
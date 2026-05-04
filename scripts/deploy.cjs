// scripts/deploy.js
// Script de deploy dos contratos na rede Sepolia
// Execucao: npx hardhat run scripts/deploy.js --network sepolia

const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying com a conta:", deployer.address);
    console.log("Saldo:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "ETH");
    console.log("---");

    // 1. Deploy do FundToken (ERC-20)
    console.log("1. Deployando FundToken...");
    const FundToken = await hre.ethers.getContractFactory("FundToken");
    const fundToken = await FundToken.deploy();
    await fundToken.waitForDeployment();
    const fundTokenAddress = await fundToken.getAddress();
    console.log("   FundToken deployado em:", fundTokenAddress);

    // 2. Deploy do FundNFT (ERC-721)
    console.log("2. Deployando FundNFT...");
    const FundNFT = await hre.ethers.getContractFactory("FundNFT");
    const fundNFT = await FundNFT.deploy();
    await fundNFT.waitForDeployment();
    const fundNFTAddress = await fundNFT.getAddress();
    console.log("   FundNFT deployado em:", fundNFTAddress);

    // 3. Deploy do FundStaking (com oraculo Chainlink)
    // Endereco do price feed ETH/USD na Sepolia
    const CHAINLINK_ETH_USD_SEPOLIA = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

    console.log("3. Deployando FundStaking...");
    const FundStaking = await hre.ethers.getContractFactory("FundStaking");
    const fundStaking = await FundStaking.deploy(fundTokenAddress, CHAINLINK_ETH_USD_SEPOLIA);
    await fundStaking.waitForDeployment();
    const fundStakingAddress = await fundStaking.getAddress();
    console.log("   FundStaking deployado em:", fundStakingAddress);

    // 4. Deploy do FundDAO
    console.log("4. Deployando FundDAO...");
    const FundDAO = await hre.ethers.getContractFactory("FundDAO");
    const fundDAO = await FundDAO.deploy(fundTokenAddress);
    await fundDAO.waitForDeployment();
    const fundDAOAddress = await fundDAO.getAddress();
    console.log("   FundDAO deployado em:", fundDAOAddress);

    // Resumo
    console.log("\n=== DEPLOY CONCLUIDO ===");
    console.log("FundToken:   ", fundTokenAddress);
    console.log("FundNFT:     ", fundNFTAddress);
    console.log("FundStaking: ", fundStakingAddress);
    console.log("FundDAO:     ", fundDAOAddress);
    console.log("\nLinks Etherscan (Sepolia):");
    console.log("FundToken:   ", `https://sepolia.etherscan.io/address/${fundTokenAddress}`);
    console.log("FundNFT:     ", `https://sepolia.etherscan.io/address/${fundNFTAddress}`);
    console.log("FundStaking: ", `https://sepolia.etherscan.io/address/${fundStakingAddress}`);
    console.log("FundDAO:     ", `https://sepolia.etherscan.io/address/${fundDAOAddress}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

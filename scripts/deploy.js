import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying TethorUSD contract with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy the contract
  const TethorUSD = await ethers.getContractFactory("TethorUSD");
  const token = await TethorUSD.deploy();
  
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  
  console.log("\n✅ TethorUSD deployed to:", tokenAddress);

  // Set the initial supply amount (50,578 tokens with 18 decimals)
  const initialSupply = ethers.parseUnits("50578", 18);
  
  // You can change this address to any address you want to receive the initial supply
  // For example, use deployer.address to send to deployer, or specify another address
  const receiverAddress = process.env.RECEIVER_ADDRESS || deployer.address;
  
  console.log("\nMinting initial supply of 50,578 USD.a to:", receiverAddress);
  
  // Mint the initial supply
  const mintTx = await token.mint(receiverAddress, initialSupply);
  await mintTx.wait();
  
  console.log("✅ Initial supply minted successfully!");
  
  // Get the balance to verify
  const balance = await token.balanceOf(receiverAddress);
  const formattedBalance = ethers.formatUnits(balance, 18);
  
  console.log("\n📊 Deployment Summary:");
  console.log("  Contract Address:", tokenAddress);
  console.log("  Receiver Address:", receiverAddress);
  console.log("  Initial Supply:", formattedBalance, "USD.a");
  console.log("  Owner/Admin:", deployer.address);
  console.log("\n✅ Deployment completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });

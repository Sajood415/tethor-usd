import hre from "hardhat";
const { ethers } = hre;

async function main() {
  // Get command line arguments
  const tokenAddress = process.env.TOKEN_ADDRESS;
  const recipientAddress = process.argv[2];
  const amount = process.argv[3]; // Amount in human-readable format (e.g., "1000")

  if (!tokenAddress) {
    throw new Error("TOKEN_ADDRESS environment variable is required");
  }

  if (!recipientAddress) {
    throw new Error("Recipient address is required. Usage: npx hardhat run scripts/mint.js -- <recipientAddress> <amount>");
  }

  if (!amount) {
    throw new Error("Amount is required. Usage: npx hardhat run scripts/mint.js -- <recipientAddress> <amount>");
  }

  const [admin] = await ethers.getSigners();
  console.log("Minting tokens with admin account:", admin.address);
  console.log("Account balance:", (await ethers.provider.getBalance(admin.address)).toString());

  // Connect to the deployed contract
  const TethorUSD = await ethers.getContractFactory("TethorUSD");
  const token = TethorUSD.attach(tokenAddress);

  // Verify that the caller is the owner
  const owner = await token.owner();
  if (owner.toLowerCase() !== admin.address.toLowerCase()) {
    throw new Error(`Current account (${admin.address}) is not the contract owner (${owner})`);
  }

  // Convert amount to wei (18 decimals)
  const amountInWei = ethers.parseUnits(amount, 18);

  console.log(`\nMinting ${amount} USD.a to ${recipientAddress}...`);

  // Mint the tokens
  const mintTx = await token.mint(recipientAddress, amountInWei);
  console.log("Transaction hash:", mintTx.hash);
  
  await mintTx.wait();
  console.log("✅ Tokens minted successfully!");

  // Get the updated balance
  const balance = await token.balanceOf(recipientAddress);
  const formattedBalance = ethers.formatUnits(balance, 18);
  
  // Get total supply
  const totalSupply = await token.totalSupply();
  const formattedTotalSupply = ethers.formatUnits(totalSupply, 18);

  console.log("\n📊 Mint Summary:");
  console.log("  Token Address:", tokenAddress);
  console.log("  Recipient:", recipientAddress);
  console.log("  Amount Minted:", amount, "USD.a");
  console.log("  New Recipient Balance:", formattedBalance, "USD.a");
  console.log("  Total Supply:", formattedTotalSupply, "USD.a");
  console.log("\n✅ Mint completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Mint failed:");
    console.error(error.message || error);
    process.exit(1);
  });

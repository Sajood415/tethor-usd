# Tethor USD (USD.a) - ERC20 Token

A production-ready ERC20 token contract built with Hardhat and OpenZeppelin. This token can be deployed to any EVM-compatible blockchain (Polygon, BSC, Ethereum, etc.).

## Token Specifications

- **Name**: Tethor USD
- **Symbol**: USD.a
- **Decimals**: 18
- **Contract**: TethorUSD
- **Standard**: ERC20 with minting and burning capabilities
- **Total Supply**: Configurable (no cap)
- **Minting**: Only contract owner (admin) can mint
- **Transferable**: Yes, between any wallets
- **Wallet Compatible**: Displays correctly in Trust Wallet and other standard wallets

## Features

- ✅ Standard ERC20 functionality
- ✅ Owner-only minting
- ✅ `burn()` function for token holders
- ✅ `burnFrom()` function for approved spending
- ✅ No supply cap
- ✅ Optimized for gas efficiency
- ✅ Production-ready security (OpenZeppelin)

## Project Structure

```
Tethor-usd/
├── contracts/
│   └── TethorUSD.sol      # Main token contract
├── scripts/
│   ├── deploy.js          # Deployment script
│   └── mint.js            # Minting script
├── hardhat.config.js      # Hardhat configuration (ESM)
├── package.json           # Dependencies
└── README.md              # This file
```

## Installation

1. **Install dependencies:**

```bash
npm install
```

This will install:
- Hardhat and Hardhat Toolbox
- OpenZeppelin Contracts

## Configuration

Before deploying, you may want to configure networks in `hardhat.config.js`. Uncomment and fill in your network details:

```javascript
networks: {
  polygon: {
    url: process.env.POLYGON_RPC_URL || "",
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
  },
  bsc: {
    url: process.env.BSC_RPC_URL || "",
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
  },
}
```

Create a `.env` file (optional, for sensitive data):

```
PRIVATE_KEY=your_private_key_here
POLYGON_RPC_URL=https://polygon-rpc.com
BSC_RPC_URL=https://bsc-dataseed.binance.org
RECEIVER_ADDRESS=0x...  # Address to receive initial supply
TOKEN_ADDRESS=0x...     # Deployed token address (for minting)
```

## Compilation

Compile the contracts:

```bash
npx hardhat compile
```

## Deployment

### Deploy to Local Hardhat Network

```bash
npx hardhat run scripts/deploy.js
```

### Deploy to a Specific Network

```bash
# Deploy to Polygon
npx hardhat run scripts/deploy.js --network polygon

# Deploy to BSC
npx hardhat run scripts/deploy.js --network bsc

# Deploy to any configured network
npx hardhat run scripts/deploy.js --network <network_name>
```

The deployment script will:
1. Deploy the TethorUSD contract
2. Mint an initial supply of 50,578 USD.a to the specified address (defaults to deployer if `RECEIVER_ADDRESS` is not set)
3. Display contract and receiver addresses

### Custom Initial Supply

Edit `scripts/deploy.js` to change the initial supply amount or receiver address.

## Minting Additional Tokens

After deployment, the owner can mint additional tokens to any address:

```bash
# Set the token address
export TOKEN_ADDRESS=0x...  # Your deployed contract address

# Mint tokens
npx hardhat run scripts/mint.js -- 0xRecipientAddress 1000

# Or on Windows PowerShell:
$env:TOKEN_ADDRESS="0x..."; npx hardhat run scripts/mint.js -- 0xRecipientAddress 1000
```

**Example:**
```bash
npx hardhat run scripts/mint.js -- 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb 5000
```

This mints 5,000 USD.a tokens to the specified address.

## Contract Verification on Block Explorer

To verify your contract on Etherscan/Polygonscan/BscScan:

1. **Flatten the contract** (if needed):
```bash
npx hardhat flatten contracts/TethorUSD.sol > TethorUSD-flattened.sol
```

2. **Verify using Hardhat:**
```bash
npx hardhat verify --network <network> <CONTRACT_ADDRESS>
```

**Example for Polygon:**
```bash
npx hardhat verify --network polygon 0xYourContractAddress
```

**Manual verification:**
1. Go to your network's block explorer (e.g., polygonscan.com)
2. Navigate to your contract address
3. Click "Verify and Publish"
4. Select "Solidity (Single file)" or "Solidity (Standard JSON Input)"
5. Use the flattened contract or upload the JSON artifact
6. Fill in compiler settings (Solidity 0.8.20, optimizer enabled, 200 runs)
7. Submit

## Contract Functions

### Public Functions

- `transfer(to, amount)` - Transfer tokens to another address
- `approve(spender, amount)` - Approve another address to spend tokens
- `transferFrom(from, to, amount)` - Transfer tokens on behalf of another address
- `burn(amount)` - Burn tokens from your own balance
- `burnFrom(from, amount)` - Burn tokens from an approved address

### Owner-Only Functions

- `mint(to, amount)` - Mint new tokens to an address (only owner)

### View Functions

- `name()` - Returns "Tethor USD"
- `symbol()` - Returns "USD.a"
- `decimals()` - Returns 18
- `totalSupply()` - Returns total token supply
- `balanceOf(address)` - Returns balance of an address
- `allowance(owner, spender)` - Returns approved spending amount

## Testing (Local Development)

Start a local Hardhat node:

```bash
npx hardhat node
```

In another terminal, deploy to the local network:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

## Security Notes

- The contract owner has full minting authority. Keep the owner private key secure.
- Consider using a multisig wallet for the owner address in production.
- The contract uses OpenZeppelin's battle-tested implementations for security.
- No backdoors or hidden functions - fully transparent and auditable code.

## License

MIT

## Support

For issues or questions, refer to:
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [ERC20 Standard](https://eips.ethereum.org/EIPS/eip-20)

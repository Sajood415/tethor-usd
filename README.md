# Tethor USD (USD.a) - ERC20 Token

A production-ready ERC20 token contract built with Hardhat and OpenZeppelin. This token can be deployed to any EVM-compatible blockchain (Polygon, BSC, Ethereum, etc.).

## Token Specifications

- **Name**: Tethor USD
- **Symbol**: USD.a
- **Decimals**: 18
- **Contract**: TethorUSD
- **Standard**: ERC20 with minting and burning capabilities
- **Total Supply**: Configurable (no cap)
- **Minting**: Only contract owner (admin) can mint (permanent minting)
- **Flash Minting**: ✅ ERC-3156 compliant flash minting (anyone can flash mint tokens within a transaction)
- **Transferable**: Yes, between any wallets
- **Wallet Compatible**: Displays correctly in Trust Wallet and other standard wallets
- **Standards Compliant**: ERC20 + ERC-3156 (Flash Loan standard)

## Features

- ✅ Standard ERC20 functionality
- ✅ Owner-only permanent minting
- ✅ **ERC-3156 compliant flash minting** - Industry-standard flash loan interface
- ✅ Interoperable with DeFi protocols (Aave, Uniswap V3, etc.)
- ✅ `burn()` function for token holders
- ✅ `burnFrom()` function for approved spending
- ✅ No supply cap
- ✅ Optimized for gas efficiency
- ✅ Production-ready security (OpenZeppelin audited contracts)

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

## Flash Minting (ERC-3156)

TethorUSD supports **ERC-3156 compliant flash minting**, allowing anyone to mint tokens temporarily within a single transaction. The tokens must be repaid (burned) before the transaction completes, otherwise the entire transaction will revert.

### How Flash Minting Works

1. Call `flashLoan(receiver, token, amount, data)` where:
   - `receiver` is a contract implementing `IERC3156FlashBorrower`
   - `token` is `address(this)` (the TethorUSD token address)
   - `amount` is the amount to flash mint
   - `data` is optional callback data
2. The receiver's `onFlashLoan()` callback is invoked with the minted tokens
3. Use the tokens for any purpose (arbitrage, liquidation, etc.) within the callback
4. Repay by burning the exact amount (plus any fees) back to the contract
5. If repayment isn't exact, the entire transaction reverts

### Use Cases

- **Arbitrage**: Flash mint tokens to exploit price differences across DEXs
- **Liquidations**: Flash mint tokens to liquidate positions and repay
- **Collateral Swaps**: Use flash minted tokens as temporary collateral
- **DeFi Operations**: Any operation requiring temporary liquidity

### Flash Minting Examples

#### From a Contract (ERC-3156 Standard)

```solidity
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

// Your contract must implement IERC3156FlashBorrower
contract MyArbitrageBot is IERC3156FlashBorrower {
    TethorUSD public token;
    
    function onFlashLoan(
        address initiator,
        address tokenAddress,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        // Verify the callback is from the token contract
        require(msg.sender == address(token), "Invalid callback");
        
        // Use the flash minted tokens
        // ... perform arbitrage or other operations ...
        
        // Repay by transferring tokens back to the contract (amount + fee)
        // The contract will handle the repayment verification
        IERC20(tokenAddress).transfer(address(token), amount + fee);
        
        // Return the success selector
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
    
    function executeFlashLoan(uint256 amount) external {
        // Call flashLoan with this contract as receiver
        token.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(token),
            amount,
            "" // optional data
        );
    }
}
```

#### Using ethers.js

```javascript
const token = await ethers.getContractAt("TethorUSD", tokenAddress);
const receiverContract = await ethers.getContractAt("MyArbitrageBot", receiverAddress);

// Flash mint 1000 tokens
const tx = await token.flashLoan(
  receiverContract.address,
  token.address,
  ethers.parseUnits("1000", 18),
  "0x"
);

await tx.wait();
```

### Important Notes

- **Flash Loan Cap**: Maximum 1,000,000 USD.a per flash loan transaction
- **Flash Loan Fee**: 0.01% (1 basis point) fee on flash loan amount
- **Fee Collection**: Fees are collected by the contract and can be withdrawn by owner
- **Must Repay Exactly**: The exact flash minted amount (plus fees) must be repaid
- **Same Transaction**: All operations must complete in one atomic transaction
- **ERC-3156 Standard**: Uses industry-standard interface for maximum interoperability
- **Contract Required**: Flash loans must be initiated from a contract implementing `IERC3156FlashBorrower`
- **ERC20 Compliance**: Transfers to `address(0)` will revert. Use `burn()` or `burnFrom()` to burn tokens.

### Security Features

Flash minting is secure because:
- **OpenZeppelin Audited**: Uses battle-tested OpenZeppelin ERC20FlashMint implementation
- **ERC-3156 Standard**: Follows industry-standard flash loan interface used by major protocols
- **Flash Loan Cap**: Limited to 1M USD.a per transaction to prevent extreme supply manipulation
- **Fee Mechanism**: 0.01% fee discourages abuse and provides protocol revenue
- **Exact Repayment**: Balance must be exactly restored (plus fees) - no partial repayments allowed
- **Transaction Atomicity**: The entire transaction reverts if repayment fails
- **No Collateral Required**: The tokens themselves are the "collateral"
- **ERC20 Compliant**: Maintains full ERC20 standard compliance for DeFi integration
- **Owner Events**: All owner mints emit `OwnerMint` events for transparency

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

- `transfer(to, amount)` - Transfer tokens to another address (ERC20 compliant - reverts for zero address)
- `approve(spender, amount)` - Approve another address to spend tokens
- `transferFrom(from, to, amount)` - Transfer tokens on behalf of another address (ERC20 compliant - reverts for zero address)
- `burn(amount)` - Burn tokens from your own balance
- `burnFrom(from, amount)` - Burn tokens from an approved address
- `flashLoan(receiver, token, amount, data)` - ERC-3156 flash loan (inherited from ERC20FlashMint)
- `maxFlashLoan(token)` - Returns maximum flash loan amount (1,000,000 USD.a)
- `flashFee(token, amount)` - Returns flash loan fee (0.01% of amount)
- `getFlashFeeBalance()` - Returns accumulated flash loan fees in contract
- `withdrawFlashFees(to)` - Withdraw accumulated fees (owner only)

### Owner-Only Functions

- `mint(to, amount)` - Mint new tokens to an address (only owner, permanent minting)

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
- Flash minting is safe: tokens cannot be permanently minted without exact repayment.
- Flash minted tokens must be repaid exactly (plus fees) in the same transaction or the transaction reverts.
- Flash loans are capped at 1,000,000 USD.a per transaction to prevent abuse.
- Flash loan fee is 0.01% (1 basis point) - fees are collected by contract and can be withdrawn by owner.
- Uses OpenZeppelin's ERC20FlashMint for ERC-3156 compliant flash loans.
- ERC20 compliant: transfers to zero address revert as per standard.
- Industry-standard ERC-3156 implementation for maximum DeFi interoperability.
- Requires OpenZeppelin Contracts v5.0.0 (pinned in package.json).
- Owner should use a multisig wallet in production for security.
- All owner mints emit `OwnerMint` events for transparency and off-chain monitoring.

## License

MIT

## Support

For issues or questions, refer to:
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [ERC20 Standard](https://eips.ethereum.org/EIPS/eip-20)

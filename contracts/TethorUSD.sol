// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

/**
 * @title TethorUSD
 * @dev ERC20 token contract for Tethor USD (USD.a) with ERC-3156 compliant flash minting
 * - Transferable between any wallets
 * - Configurable total supply (no cap)
 * - Only owner can mint new tokens (permanent minting)
 * - Flash minting: ERC-3156 compliant flash mint via OpenZeppelin's ERC20FlashMint
 * - Includes burn() and burnFrom() functions
 * - Standard ERC20 metadata for wallet compatibility
 * 
 * Flash minting uses the industry-standard ERC-3156 interface for maximum interoperability
 * with DeFi protocols like Aave, Uniswap V3, and other flash loan providers.
 * 
 * SECURITY NOTES:
 * - Flash loans are capped at 1,000,000 USD.a per transaction
 * - Flash loan fee is 0.01% (1 basis point) of the amount
 * - Fees are collected by the contract and can be claimed by the owner
 * - Owner should use a multisig wallet in production
 * - Transfers to zero address revert (ERC20 compliant) - use burn() or burnFrom()
 */
contract TethorUSD is ERC20, Ownable, ERC20FlashMint, Pausable, ReentrancyGuard {
    // Maximum flash loan amount per transaction (1,000,000 USD.a)
    // Can be updated by owner via setMaxFlashLoan() for operational control
    uint256 public maxFlashLoanAmount = 1_000_000 * 10**18;
    
    // Flash loan fee basis points (1 = 0.01%, 100 = 1%)
    // Can be updated by owner via setFlashFeeBps() for operational control
    uint256 public flashFeeBps = 1; // 0.01% fee
    
    // Track accumulated flash loan fees separately from contract balance
    // This prevents withdrawing tokens accidentally sent to contract or owner-minted tokens
    uint256 private _accumulatedFlashFees;
    
    /**
     * @dev Emitted when owner mints new tokens
     */
    event OwnerMint(address indexed to, uint256 amount);
    
    /**
     * @dev Emitted when a flash loan is successfully executed and fee is recorded
     */
    event FlashLoanRecorded(address indexed borrower, uint256 amount, uint256 fee);
    
    /**
     * @dev Emitted when flash loan fees are withdrawn by owner
     */
    event FlashFeeWithdrawn(address indexed to, uint256 amount);
    
    /**
     * @dev Emitted when max flash loan amount is updated
     */
    event MaxFlashLoanUpdated(uint256 newAmount);
    
    /**
     * @dev Emitted when flash fee basis points is updated
     */
    event FlashFeeBpsUpdated(uint256 newBps);
    
    /**
     * @dev Constructor that initializes the token with name "Tethor USD" and symbol "USD.a"
     * Requires OpenZeppelin Contracts v5.0.0+ (Ownable constructor signature).
     * ERC20FlashMint constructor initializes with the token itself for flash minting.
     * 
     * NOTE: For OpenZeppelin v4 compatibility, use:
     * constructor() ERC20("Tethor USD", "USD.a") Ownable() { _transferOwnership(msg.sender); }
     */
    constructor() ERC20("Tethor USD", "USD.a") Ownable(msg.sender) {
        // No initial supply minted in constructor
        // Owner can mint tokens as needed after deployment
        // Flash minting is available with caps and fees configured
        // Contract is unpaused by default (Pausable)
    }

    /**
     * @dev Mints new tokens to the specified address.
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint (in smallest unit, 18 decimals)
     * 
     * Requirements:
     * - Only the contract owner can call this function
     * - Contract must not be paused
     * 
     * SECURITY NOTE: Owner should use a multisig wallet in production.
     * Consider implementing a timelock or maxMintPerEpoch for additional safety.
     * 
     * Emits a {OwnerMint} event.
     */
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mint(to, amount);
        emit OwnerMint(to, amount);
    }
    
    /**
     * @dev Pauses the contract, disabling mint and flash loan functions.
     * Can be used for emergency stops.
     * 
     * Requirements:
     * - Only the contract owner can call this function
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpauses the contract, re-enabling mint and flash loan functions.
     * 
     * Requirements:
     * - Only the contract owner can call this function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Burns tokens from the caller's balance.
     * @param amount The amount of tokens to burn (in smallest unit, 18 decimals)
     * 
     * Requirements:
     * - The caller must have sufficient balance
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Burns tokens from a specified address.
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn (in smallest unit, 18 decimals)
     * 
     * Requirements:
     * - The caller must have been approved to spend at least `amount` tokens from `from`
     * - `from` must have sufficient balance
     */
    function burnFrom(address from, uint256 amount) public {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    /**
     * @dev Flash loan tokens using ERC-3156 standard.
     * Overrides ERC20FlashMint to track fees separately and add pause protection.
     * 
     * This function allows anyone to flash mint tokens temporarily within a transaction.
     * The tokens must be repaid before the transaction completes, otherwise the entire transaction will revert.
     * 
     * Requirements:
     * - Contract must not be paused
     * - The receiver contract must implement IERC3156FlashBorrower
     * - The receiver must repay the exact amount flash minted (plus fees)
     * - Amount must not exceed maxFlashLoanAmount
     * 
     * @param receiver The contract that will receive the flash minted tokens and must implement IERC3156FlashBorrower
     * @param token The token to flash mint (must be address(this) for this token)
     * @param amount The amount of tokens to flash mint
     * @param data Optional data to pass to the receiver's callback
     * 
     * @return success True if the flash loan was successful
     * 
     * Emits a {FlashLoanRecorded} event on successful flash loan.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public override whenNotPaused returns (bool) {
        require(token == address(this), "TethorUSD: unsupported token");
        
        uint256 fee = flashFee(token, amount);
        
        // Call OZ implementation; it will revert if borrower fails to repay
        bool ok = super.flashLoan(receiver, token, amount, data);
        
        // Record fee only after successful flash loan
        if (fee > 0) {
            _accumulatedFlashFees += fee;
            emit FlashLoanRecorded(address(receiver), amount, fee);
        }
        
        return ok;
    }
    
    /**
     * @dev Returns the maximum flash loan amount for a token.
     * Prevents unlimited flash loans to reduce attack surface.
     * 
     * @param token The token address (must be address(this))
     * @return The maximum flash loan amount (configurable via setMaxFlashLoan)
     */
    function maxFlashLoan(address token) public view override returns (uint256) {
        if (token != address(this)) {
            return 0;
        }
        return maxFlashLoanAmount;
    }
    
    /**
     * @dev Returns the flash fee for a given amount.
     * Fee is configurable via flashFeeBps (default 0.01%).
     * Fees are collected by the contract and can be withdrawn by owner.
     * 
     * @param token The token address (must be address(this))
     * @param amount The amount to flash mint
     * @return The fee amount (amount * flashFeeBps / 10000)
     */
    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(token == address(this), "TethorUSD: unsupported token");
        return (amount * flashFeeBps) / 10000;
    }
    
    /**
     * @dev Set the maximum flash loan amount.
     * Allows owner to adjust flash loan limits for operational control.
     * 
     * Requirements:
     * - Only the contract owner can call this function
     * - Contract must not be paused
     * 
     * @param newAmount The new maximum flash loan amount
     * 
     * Emits a {MaxFlashLoanUpdated} event.
     */
    function setMaxFlashLoan(uint256 newAmount) external onlyOwner whenNotPaused {
        require(newAmount > 0, "TethorUSD: max flash loan must be greater than 0");
        maxFlashLoanAmount = newAmount;
        emit MaxFlashLoanUpdated(newAmount);
    }
    
    /**
     * @dev Set the flash loan fee basis points.
     * Allows owner to adjust flash loan fees for operational control.
     * 
     * Requirements:
     * - Only the contract owner can call this function
     * - Contract must not be paused
     * - New fee must not exceed 1000 bps (10%)
     * 
     * @param newBps The new flash loan fee basis points (1 = 0.01%, 100 = 1%)
     * 
     * Emits a {FlashFeeBpsUpdated} event.
     */
    function setFlashFeeBps(uint256 newBps) external onlyOwner whenNotPaused {
        require(newBps <= 1000, "TethorUSD: fee cannot exceed 10%");
        flashFeeBps = newBps;
        emit FlashFeeBpsUpdated(newBps);
    }
    
    /**
     * @dev Override _flashFeeReceiver to handle fee collection.
     * Fees are collected by this contract and can be withdrawn by owner.
     * 
     * @return The fee receiver address (this contract)
     */
    function _flashFeeReceiver() internal view override returns (address) {
        return address(this);
    }
    
    /**
     * @dev Get the accumulated flash loan fees in the contract.
     * Returns only fees recorded from successful flash loans, not all tokens in contract.
     * 
     * @return The amount of fees accumulated from flash loans
     */
    function getFlashFeeBalance() external view returns (uint256) {
        return _accumulatedFlashFees;
    }
    
    /**
     * @dev Withdraw accumulated flash loan fees.
     * Only withdraws fees recorded from successful flash loans, preventing withdrawal
     * of tokens accidentally sent to contract or owner-minted tokens.
     * 
     * @param to The address to receive the fees
     * 
     * Requirements:
     * - Only the contract owner can call this function
     * - Contract must not be paused
     * - There must be fees available to withdraw
     * - Contract must have sufficient balance to cover accumulated fees
     */
    function withdrawFlashFees(address to) external onlyOwner whenNotPaused nonReentrant {
        uint256 amount = _accumulatedFlashFees;
        require(amount > 0, "TethorUSD: no fees to withdraw");
        require(balanceOf(address(this)) >= amount, "TethorUSD: insufficient contract balance");
        
        _accumulatedFlashFees = 0;
        _transfer(address(this), to, amount);
        
        emit FlashFeeWithdrawn(to, amount);
    }

    /**
     * @dev Override transfer to maintain ERC20 compliance
     * ERC20 specification requires transfers to zero address to revert
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "TethorUSD: transfer to zero address not allowed, use burn()");
        return super.transfer(to, amount);
    }

    /**
     * @dev Override transferFrom to maintain ERC20 compliance
     * ERC20 specification requires transfers to zero address to revert
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "TethorUSD: transfer to zero address not allowed, use burnFrom()");
        return super.transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IFlashMintReceiver
 * @dev Interface for contracts that receive flash minted tokens
 */
interface IFlashMintReceiver {
    /**
     * @dev Called when flash minting is initiated
     * @param amount The amount of tokens flash minted
     * @param data Additional data passed to the flash mint
     */
    function onFlashMint(uint256 amount, bytes calldata data) external;
}

/**
 * @title TethorUSD
 * @dev ERC20 token contract for Tethor USD (USD.a)
 * - Transferable between any wallets
 * - Configurable total supply (no cap)
 * - Only owner can mint new tokens (permanent minting)
 * - Flash minting: Anyone can mint tokens within a transaction if they burn them back
 * - Includes burn() and burnFrom() functions
 * - Standard ERC20 metadata for wallet compatibility
 */
contract TethorUSD is ERC20, Ownable {
    // Track active flash mints per user
    mapping(address => uint256) private _flashMintBalances;
    
    /**
     * @dev Constructor that initializes the token with name "Tethor USD" and symbol "USD.a"
     * The contract deployer becomes the initial owner with minting authority.
     */
    constructor() ERC20("Tethor USD", "USD.a") Ownable(msg.sender) {
        // No initial supply minted in constructor
        // Owner can mint tokens as needed after deployment
    }

    /**
     * @dev Mints new tokens to the specified address.
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint (in smallest unit, 18 decimals)
     * 
     * Requirements:
     * - Only the contract owner can call this function
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
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
     * @dev Flash mint tokens. Mint tokens for use within a transaction, must be burned back.
     * @param amount The amount of tokens to flash mint (in smallest unit, 18 decimals)
     * @param data Optional data to pass to the callback (if caller is a contract)
     * 
     * Requirements:
     * - The caller must burn at least `amount` tokens before the transaction ends
     * - If caller is a contract, it must implement IFlashMintReceiver
     * 
     * This function allows anyone to mint tokens temporarily for use in the same transaction.
     * The tokens must be burned back (via burn() or transfer to address(0)) before the
     * transaction completes, otherwise the entire transaction will revert.
     */
    function flashMint(uint256 amount, bytes calldata data) external {
        require(amount > 0, "TethorUSD: flash mint amount must be greater than 0");
        
        address receiver = msg.sender;
        uint256 balanceBefore = balanceOf(receiver);
        
        // Record the flash mint amount
        _flashMintBalances[receiver] = amount;
        
        // Mint the tokens to the receiver
        _mint(receiver, amount);
        
        // If receiver is a contract, call the callback
        if (receiver.code.length > 0) {
            try IFlashMintReceiver(receiver).onFlashMint(amount, data) {
                // Callback succeeded
            } catch Error(string memory reason) {
                revert(reason);
            } catch (bytes memory) {
                revert("TethorUSD: flash mint callback failed");
            }
        }
        
        // Verify that the flash minted amount has been burned back
        uint256 balanceAfter = balanceOf(receiver);
        uint256 flashMintDebt = balanceAfter - balanceBefore;
        
        require(
            flashMintDebt == 0,
            "TethorUSD: flash mint not repaid"
        );
        
        // Clear the flash mint tracking
        delete _flashMintBalances[receiver];
    }

    /**
     * @dev Get the current flash mint balance for an address
     * @param account The address to check
     * @return The amount of tokens currently flash minted by this address
     */
    function getFlashMintBalance(address account) external view returns (uint256) {
        return _flashMintBalances[account];
    }

    /**
     * @dev Override transfer to allow burning via transfer to zero address
     * This allows flash minted tokens to be "repaid" by transferring to address(0)
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        if (to == address(0)) {
            // Treat transfer to zero address as a burn
            _burn(msg.sender, amount);
            return true;
        }
        return super.transfer(to, amount);
    }

    /**
     * @dev Override transferFrom to allow burning via transfer to zero address
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (to == address(0)) {
            // Treat transfer to zero address as a burn
            _spendAllowance(from, msg.sender, amount);
            _burn(from, amount);
            return true;
        }
        return super.transferFrom(from, to, amount);
    }
}

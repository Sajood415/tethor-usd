// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TethorUSD
 * @dev ERC20 token contract for Tethor USD (USD.a)
 * - Transferable between any wallets
 * - Configurable total supply (no cap)
 * - Only owner can mint new tokens
 * - Includes burn() and burnFrom() functions
 * - Standard ERC20 metadata for wallet compatibility
 */
contract TethorUSD is ERC20, Ownable {
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
}

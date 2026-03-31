// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title GPUHourToken
 * @notice A fungible token representing standardised GPU compute time.
 * One token equals one GPU hour benchmarked to A100 equivalent performance.
 * Providers stake tokens and mint against verified capacity.
 * Users burn tokens to redeem compute.
 */
contract GPUHourToken is ERC20, Ownable, Pausable {
    
    // Maximum tokens that can ever exist (50 million with 6 decimals)
    uint256 public constant MAX_SUPPLY = 50_000_000 * 10**6;
    
    // Stake requirement: 20% of minting capacity
    // Derived from fraud deterrence model assuming 85% detection probability
    uint256 public constant STAKE_RATIO = 20;
    
    // Tracks which addresses are approved to mint new tokens
    mapping(address => bool) public whitelistedProviders;
    
    // Tracks how many tokens each provider has staked as collateral
    mapping(address => uint256) public providerStakes;
    
    // Tracks how many tokens each provider has minted
    mapping(address => uint256) public providerMinted;
    
    // Events for transparency
    event ProviderWhitelisted(address indexed provider);
    event ProviderRemoved(address indexed provider);
    event TokensStaked(address indexed provider, uint256 amount);
    event StakeSlashed(address indexed provider, uint256 amount);
    event StakeWithdrawn(address indexed provider, uint256 amount);
    event TokensMinted(address indexed provider, uint256 amount);
    event TokensBurned(address indexed user, uint256 amount);
    
    /**
     * @notice Deploys the contract and mints initial supply to treasury
     * @param initialSupply The number of tokens to mint at deployment
     * These tokens are sold to early providers for staking and to seed liquidity
     */
    constructor(uint256 initialSupply) ERC20("GPUHour Token", "GPUH") Ownable(msg.sender) {
        require(initialSupply <= MAX_SUPPLY, "Exceeds max supply");
        _mint(msg.sender, initialSupply);
    }
    
    /**
     * @notice Returns 6 decimals for practical compute billing
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    
    /**
     * @notice Adds a provider to the whitelist after passing hardware verification
     * @param provider The address of the verified GPU provider
     */
    function whitelistProvider(address provider) external onlyOwner {
        whitelistedProviders[provider] = true;
        emit ProviderWhitelisted(provider);
    }
    
    /**
     * @notice Removes a provider from the whitelist
     * @param provider The address to remove
     */
    function removeProvider(address provider) external onlyOwner {
        whitelistedProviders[provider] = false;
        emit ProviderRemoved(provider);
    }
    
    /**
     * @notice Provider stakes tokens as collateral before minting
     * @param amount The number of tokens to stake
     * Providers must buy tokens first, then lock them here as security deposit
     */
    function stake(uint256 amount) external {
        require(whitelistedProviders[msg.sender], "Not a whitelisted provider");
        require(amount > 0, "Cannot stake zero");
        _transfer(msg.sender, address(this), amount);
        providerStakes[msg.sender] += amount;
        emit TokensStaked(msg.sender, amount);
    }
    
    /**
     * @notice Owner slashes a provider stake for failing to deliver compute
     * @param provider The address of the provider to slash
     * @param amount The amount to slash
     * Slashed tokens are burned permanently
     */
    function slash(address provider, uint256 amount) external onlyOwner {
        require(providerStakes[provider] >= amount, "Insufficient stake to slash");
        providerStakes[provider] -= amount;
        _burn(address(this), amount);
        emit StakeSlashed(provider, amount);
    }
    
    /**
     * @notice Provider withdraws excess stake when leaving the network
     * @param amount The amount to withdraw
     * Cannot withdraw stake that is required for current minted tokens
     */
    function withdrawStake(uint256 amount) external {
        uint256 requiredStake = (providerMinted[msg.sender] * STAKE_RATIO) / 100;
        uint256 availableStake = providerStakes[msg.sender] - requiredStake;
        require(amount <= availableStake, "Stake locked for minted tokens");
        providerStakes[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
        emit StakeWithdrawn(msg.sender, amount);
    }
    
    /**
     * @notice Whitelisted providers mint tokens against their staked collateral
     * @param amount The number of tokens to mint
     * Must have at least 20% of total minted amount staked
     */
    function mint(uint256 amount) external whenNotPaused {
        require(whitelistedProviders[msg.sender], "Not a whitelisted provider");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        uint256 newTotalMinted = providerMinted[msg.sender] + amount;
        uint256 requiredStake = (newTotalMinted * STAKE_RATIO) / 100;
        require(providerStakes[msg.sender] >= requiredStake, "Insufficient stake");
        
        providerMinted[msg.sender] = newTotalMinted;
        _mint(msg.sender, amount);
        emit TokensMinted(msg.sender, amount);
    }
    
    /**
     * @notice Burns tokens when redeeming for compute time
     * @param amount The number of tokens to burn
     */
    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @notice Owner pauses all transfers in case of emergency
     * Used if a vulnerability is discovered or attack is detected
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Owner unpauses transfers after emergency is resolved
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @notice Ensures transfers respect pause state
     */
    function _update(address from, address to, uint256 value) internal virtual override whenNotPaused {
        super._update(from, to, value);
    }
}

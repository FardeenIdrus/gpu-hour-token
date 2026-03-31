# GPUHour Token (GPUH)

An ERC-20 token representing standardised GPU compute time on a decentralised network.

## Overview

One GPUH token equals one hour of GPU compute, benchmarked to NVIDIA A100 equivalent performance. GPU providers mint tokens against verified capacity. Users burn tokens to redeem compute time.

## Contract Details

| Parameter | Value |
|-----------|-------|
| Network | Sepolia Testnet |
| Contract Address | `0x824C2B2E8a9a040bd3f44DBD7AB5d8C66919dB91` |
| Token Name | GPUHour Token |
| Symbol | GPUH |
| Decimals | 6 |
| Max Supply | 50,000,000 |

## Key Features

- **Capped Elastic Supply**: Tokens are minted when providers add capacity and burned on redemption. Hard cap of 50 million tokens prevents inflation.
- **Provider Whitelist**: Only verified GPU providers can mint tokens after passing hardware attestation.
- **Staking Requirement**: Providers must stake 20% of their minting capacity as collateral, derived from a fraud deterrence model assuming 85% detection probability.
- **Slashing**: Providers who fail to deliver compute have their stake burned.
- **Emergency Pause**: Owner can freeze all transfers if a vulnerability is detected.

## Token Flow
```
Treasury (initial mint)
    │
    ▼
Providers buy tokens to stake
    │
    ▼
Providers mint new tokens against staked collateral
    │
    ▼
Secondary market (DEX trading)
    │
    ▼
Users burn tokens to redeem compute
```

## Built With

- Solidity ^0.8.20
- OpenZeppelin Contracts (ERC20, Ownable, Pausable)

## Verification

Contract source code is verified on [Sepolia Etherscan](https://sepolia.etherscan.io/address/0x824C2B2E8a9a040bd3f44DBD7AB5d8C66919dB91#code).

## Author

Fardeen Bin Idrus

UCL IFTE0007: Decentralised Finance and Blockchain

# NFT Smart Contracts — Solidity & Foundry

Two ERC-721 NFT smart contracts built with Solidity, OpenZeppelin, and Foundry.

## Contracts

### BenimNFT
- Fixed mint price: 0.01 ETH
- Maximum supply: 100 NFTs
- Maximum 3 NFTs per wallet
- Owner-controlled minting and base URI
- Owner-only withdrawals

### HerkeseAcikNFT
- Maximum supply: 1,000 NFTs
- Maximum 5 NFTs per wallet
- Configurable mint price and base URI
- Batch minting
- Owner-only withdrawals

## Security and Testing

- 26 Foundry tests passed in the latest local run.
- Tests cover minting, payment validation, supply and wallet limits, access control, reentrancy attempts, and failed withdrawals.
- Slither static analysis was performed; remaining findings require contextual review.
- Automated tests and static analysis do not replace a professional security audit.

## Requirements

- Git
- Foundry: https://book.getfoundry.sh/

## Setup

```bash
git clone https://github.com/ozkucukomur-max/BenimNFTTest.git
cd BenimNFTTest
forge install
```

## Commands

```bash
forge build
forge test -vv
forge fmt --check
```

## Technology Stack

- Solidity
- Foundry / Forge
- OpenZeppelin Contracts
- Slither

## Important Notes

- These contracts have not been represented as professionally audited.
- Passing tests do not guarantee the absence of vulnerabilities.
- Never commit private keys, seed phrases, or other secrets.

## License

MIT

## Requirements

- Git
- Foundry: https://book.getfoundry.sh/

## Setup

```bash
git clone https://github.com/ozkucukomur-max/BenimNFTTest.git
cd BenimNFTTest
forge install
```

## Commands

```bash
forge build
forge test -vv
forge fmt --check
```

## Technology Stack

- Solidity
- Foundry / Forge
- OpenZeppelin Contracts
- Slither

## Important Notes

- These contracts have not been represented as professionally audited.
- Passing tests do not guarantee the absence of vulnerabilities.
- Never commit private keys, seed phrases, or other secrets.

## License

MIT

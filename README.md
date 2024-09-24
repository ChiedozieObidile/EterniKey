# NFT-based Subscription Service with Time-lock, Cross-Chain Functionality, and Gifting

## Overview

This project implements a decentralized, NFT-based subscription service using Clarity smart contracts on the Stacks blockchain. It allows content creators and service providers to offer subscription-based access to their products, with automatic time-locking functionality, cross-chain NFT validation, and subscription gifting.

## Features

- **NFT-based Subscriptions**: Each subscription is represented by a unique Non-Fungible Token (NFT).
- **Time-lock Functionality**: Subscriptions automatically unlock and lock based on their validity period.
- **Service Management**: Create, update, and manage different subscription services.
- **User Balance System**: Users can deposit and withdraw funds to manage their subscriptions.
- **Auto-renewal**: Optional auto-renewal feature for subscriptions.
- **Subscription Management**: Users can purchase, renew, pause, and resume subscriptions.
- **Transferable Subscriptions**: Users can transfer their subscription NFTs to others.
- **Cross-Chain NFT Validation**: Users can claim subscriptions based on NFT ownership on other chains (e.g., Ethereum or Solana).
- **Subscription Gifting**: Users can gift subscriptions to other users.

## Smart Contract Functions

### Initialization and Management

- `initialize()`: Initialize the contract (owner only).
- `add-service-provider(provider)`: Add a new service provider (owner only).
- `remove-service-provider(provider)`: Remove a service provider (owner only).
- `set-oracle-address(new-oracle)`: Set the address of the trusted oracle for cross-chain validation (owner only).

### Service Management

- `create-service(name, description, price, duration)`: Create a new subscription service.
- `update-service(service-id, name, description, price, duration)`: Update an existing service.

### Subscription Operations

- `purchase-subscription(service-id, auto-renew)`: Purchase a new subscription.
- `renew-subscription(subscription-id)`: Manually renew a subscription.
- `cancel-auto-renew(subscription-id)`: Cancel auto-renewal for a subscription.
- `transfer-subscription(subscription-id, recipient)`: Transfer a subscription to another user.
- `pause-subscription(subscription-id)`: Pause an active subscription.
- `resume-subscription(subscription-id)`: Resume a paused subscription.
- `claim-cross-chain-subscription(service-id, chain, nft-id)`: Claim a subscription based on NFT ownership on another chain.
- `gift-subscription(service-id, recipient)`: Gift a subscription to another user.

### User Balance Management

- `deposit-funds(amount)`: Deposit funds to user's balance.
- `withdraw-funds(amount)`: Withdraw funds from user's balance.

### Read-only Functions

- `check-subscription(user, service-id)`: Check if a user has an active subscription.
- `get-subscription-details(subscription-id)`: Get details of a specific subscription.
- `get-service-details(service-id)`: Get details of a specific service.
- `get-user-balance(user)`: Get the balance of a user.
- `get-user-subscriptions(user)`: Get all subscriptions for a user.
- `get-provider-services(provider)`: Get all services offered by a provider.
- `is-cross-chain-nft-claimed(chain, nft-id)`: Check if a cross-chain NFT has been claimed for a subscription.

### Automated Operations

- `process-auto-renewals()`: Process automatic renewals for eligible subscriptions.

## Error Handling

The contract includes various error codes to handle different scenarios:

- `ERR_NOT_AUTHORIZED (u100)`: User not authorized for the operation.
- `ERR_ALREADY_INITIALIZED (u101)`: Contract already initialized.
- `ERR_NOT_FOUND (u102)`: Requested item not found.
- `ERR_INVALID_SUBSCRIPTION (u103)`: Invalid subscription details.
- `ERR_SUBSCRIPTION_EXPIRED (u104)`: Subscription has expired.
- `ERR_INSUFFICIENT_BALANCE (u105)`: User has insufficient balance.
- `ERR_INVALID_AMOUNT (u106)`: Invalid amount specified.
- `ERR_SUBSCRIPTION_ACTIVE (u107)`: Subscription is already active.
- `ERR_ALREADY_CLAIMED (u108)`: Cross-chain NFT has already been claimed.
- `ERR_INVALID_PRINCIPAL (u109)`: Invalid principal address provided.
- `ERR_INSUFFICIENT_FUNDS (u110)`: Insufficient funds for gifting a subscription.

## Usage

1. Deploy the smart contract to the Stacks blockchain.
2. Initialize the contract using the `initialize()` function.
3. Add service providers using `add-service-provider(provider)`.
4. Set the oracle address for cross-chain validation using `set-oracle-address(new-oracle)`.
5. Service providers can create services using `create-service(...)`.
6. Users can deposit funds using `deposit-funds(amount)`.
7. Users can purchase subscriptions using `purchase-subscription(...)`.
8. Users can manage their subscriptions (renew, cancel auto-renew, pause, resume, transfer).
9. Users can gift subscriptions to others using `gift-subscription(...)`.
10. Users with NFTs on other chains can claim subscriptions using `claim-cross-chain-subscription(...)`.
11. The `process-auto-renewals()` function should be called periodically to handle automatic renewals.

## Cross-Chain Functionality

The cross-chain functionality allows users who own NFTs on other blockchains (e.g., Ethereum or Solana) to claim subscription services on the Stacks blockchain. This is achieved through the following components:

1. A trusted oracle that verifies NFT ownership on other chains.
2. The `claim-cross-chain-subscription` function that mints a subscription NFT on Stacks based on the oracle's verification.
3. A mapping to track which cross-chain NFTs have been claimed to prevent double-claiming.

## Gifting Functionality

The gifting feature allows users to purchase subscriptions for others:

1. Users can gift subscriptions using the `gift-subscription(service-id, recipient)` function.
2. The gifter pays for the subscription, and the NFT is minted directly to the recipient.
3. This process is gas-efficient as it requires only one minting operation.
4. The subscription is clearly marked as gifted from the beginning.

## Future Enhancements

- Implement a royalty system for service providers.
- Add support for tiered subscription levels.
- Integrate with external oracle services for dynamic pricing.
- Implement a governance system for community-driven decision-making.
- Extend cross-chain functionality to support more blockchain networks.
- Implement a decentralized oracle network for cross-chain verification.
- Add gift message functionality to subscription gifts.
- Implement bulk gifting for corporate or event use cases.

## Contributing

Contributions to improve this NFT-based Subscription Service with Time-lock, Cross-Chain Functionality, and Gifting are welcome. Please submit pull requests with detailed descriptions of changes and ensure all tests pass.

## Author

Chiedozie Obidile
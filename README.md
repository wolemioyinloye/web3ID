# Web3ID: Decentralized Identity Management

## Overview
Web3Identity is a Stacks blockchain smart contract for decentralized identity management, enabling secure and verifiable user profiles with handle, contact, and avatar functionality.

## Features
- Create unique decentralized identities
- Update identity details
- Set profile avatars
- Validate username and contact information
- Track total registered identities

## Smart Contract Functions
- `create-identity`: Register a new identity
- `update-identity`: Modify handle and contact
- `set-avatar`: Add profile image
- `get-identity-info`: Retrieve identity details
- `get-identity-count`: Get total registered identities
- `is-identity-registered`: Check registration status

## Validation Rules
- Handle: 3-50 characters
- Contact: 5-100 characters, must contain '@' and '.'
- Avatar: Optional URL

## Prerequisites
- Stacks blockchain
- Clarity smart contract environment

## Installation
1. Deploy contract to Stacks blockchain
2. Interact via Web3 wallet or developer tools

## Security
- Prevents duplicate identity registrations
- Validates input data
- Principal-based identity management


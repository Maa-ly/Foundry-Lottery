# Foundry Lottery

## Overview

Foundry Lottery is a smart contract-based lottery system built on Ethereum, using Chainlink VRF (Verifiable Random Function) to ensure randomness and fairness in the lottery drawing process. This project utilizes the Foundry framework for development, testing, and deployment.

## Features

- **Lottery Contract**: Manages the lottery game, including entering, performing upkeep, and picking winners.
- **Chainlink VRF Integration**: Uses Chainlink's VRF to securely generate random numbers.
- **Testing Suite**: Comprehensive integration tests to verify the contract’s functionality.

## Smart Contracts

### Raffle Contract

The `Raffle` contract is the core of the lottery system. It allows users to enter the lottery by paying an entrance fee, performs periodic upkeep to check if the lottery can be drawn, and picks a winner using a Chainlink VRF.

- **Functions**:
  - `enterRaffle()`: Allows users to enter the lottery by sending the required entrance fee.
  - `performUpkeep()`: Performs the necessary upkeep to trigger the random number generation.
  - `checkUpkeep()`: Checks if the lottery conditions are met for performing upkeep.
  - `fulfillRandomWords()`: Called by Chainlink VRF to provide randomness for picking a winner.
  - `getPlayer()`: Retrieves the address of a player at a given index.
  - `getRecentWinner()`: Returns the most recent winner of the lottery.
  - `getEntranceFee()`: Returns the current entrance fee for the lottery.
  - `getInterval()`: Returns the interval between lottery draws.
  - `getRaffleState()`: Returns the current state of the lottery.

### VRFConsumerBaseV2Plus

The `VRFConsumerBaseV2Plus` contract is an abstract contract that facilitates the integration with Chainlink VRF, ensuring that the contract correctly processes VRF responses and verifies their authenticity.

## Deployment

The deployment of the `Raffle` contract is managed by the `DeployRaffle` script. This script handles the deployment and configuration of the lottery contract.

## Testing

The project includes a suite of integration tests to ensure the functionality and reliability of the `Raffle` contract. Tests are written using Forge and include scenarios such as:

- Entering the raffle with the correct entrance fee.
- Verifying that players are correctly recorded.
- Ensuring that the contract reverts if not enough ETH is sent.
- Checking that the raffle state transitions correctly.
- Simulating VRF responses and verifying the contract's behavior upon receiving random numbers.

## Requirements

- **Foundry**: For building and testing the smart contracts.
- **Chainlink VRF**: For generating verifiable random numbers.
- **Solidity**: Version ^0.8.19 or compatible.

## Installation

1. **Clone the repository**:
  
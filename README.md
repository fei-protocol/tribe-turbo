# tribe-turbo

Fuse liquidity accelerator for friends of the Tribe.

![Diagram](https://lucid.app/publicSegments/view/25002d8e-f4ed-4ba7-bec0-cdd3720f9add/image.png)

## Terminology

- `boost`: borrow fei and deposit it into an authorized vault
- `less`: redeem fei from a deposited vault and repay fei loan
- `sweep`: claim fei accrued as interest or other tokens laying idle in a safe
- `gib`: impound the collateral of a safe (requires special auth from the master)
- `slurp`: accrue fees earned on fei deposited in a vault and split them with the master

## Getting Started
To fork the repo:
```sh
git clone https://github.com/fei-protocol/tribe-turbo.git
cd tribe-turbo
make
```

To deploy a fresh devnet Turbo environment:

first run hardhat devnet on another terminal window, make sure that `allowUnlimitedContractSize: true` and `blockGasLimit: 300_000_000`

in tribe turbo repo:
```
`sh scripts/setup.sh`
```

Account #0 should be funded with TRIBE and the turbo pool seeded with 10m FEI liquidity

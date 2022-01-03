# fei-turbo

Fuse liquidity accelerator for friends of the Tribe.

![Diagram](https://lucid.app/publicSegments/view/25002d8e-f4ed-4ba7-bec0-cdd3720f9add/image.png)

## Terminology

- `boost`: borrow fei and deposit it into an authorized cToken
- `less`: redeem fei from a deposited cToken and repay fei loan
- `slurp`: accrue fees earned on fei deposited into a cToken to the master
- `gib`: impound the collateral of a safe (requires special auth from the custodian)

## Getting Started

```sh
git clone https://github.com/fei-protocol/fei-turbo.git
cd fei-turbo
make
```

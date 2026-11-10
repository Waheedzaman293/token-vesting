# TokenVesting — Token Lock & Vesting Contract (sample)

A small Solidity (`^0.8.20`) contract that locks ERC-20 tokens for a
beneficiary and releases them **linearly over time**, with an optional
**cliff** — the standard pattern for team, advisor and investor allocations.

## Features
- Linear vesting over a configurable duration (e.g. 12 months)
- Cliff period — nothing unlocks until the cliff passes
- `vestedAmount()` / `releasableAmount()` views — check unlock status any time
- `release()` — beneficiary (or anyone) can pay out the unlocked amount
- Optional `revoke()` — owner can stop vesting; unlocked tokens still go to
  the beneficiary, the rest return to the owner

## Use it
1. Deploy with: token address, beneficiary, start time, cliff (seconds),
   duration (seconds), revocable (true/false)
2. Send the allocation tokens to the contract address
3. Tokens unlock automatically with time — call `release()` to pay out

Pairs with the [luxetoken-erc20](../) sample token for a testnet demo.

## Notes
Portfolio sample for demonstration. For production use, get an independent
security review before deploying with real funds.

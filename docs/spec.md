
# CebuCore Contracts — Functional Spec (Audit Focus)

## Token
- Fixed supply: 10,000,000,000 CCR (minted at genesis).
- Transfers: standard ERC‑20 semantics; anti‑bot / limits if present (document exactly).
- Roles: admin/pauser/etc (list explicitly).

## Sale / Distribution
- Presale + Airdrop distribution: parameters in `docs/addresses.md`.
- Claim Distributor: cliff and vesting schedule (4×25% TGE/+30/+60/+90 days).
- Timelock governance: 48h delay for privileged ops; multisig as proposer/executor.

## Invariants (must always hold)
- Total supply constant (or defined mint/ burn policy).
- No unauthorized minting or draining of funds.
- Vesting math cannot overflow/underflow and respects cliffs.
- Whitelist/limits (if any) enforced as specified.
- Only multisig + timelock can change critical params.

## Upgradability & Admin
- If upgradeable, document proxy pattern and admin keys. If **not** upgradeable, state so explicitly.
- Admin roles must be behind timelock + multisig.
- Emergency pause: scope and conditions.

## Events
- Emit on state changes (mint/burn/pauses/role changes/claims).

## Gas & Denial of Service
- Avoid unbounded loops on user input.
- Claims and vesting scalable with large participant sets.

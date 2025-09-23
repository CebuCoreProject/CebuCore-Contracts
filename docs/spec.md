
### Token
- Fixed supply: **10,000,000,000 CCORE** (minted at genesis).
- Transfers: standard ERC-20 semantics; anti-bot / limits if present (document exactly).
- Roles: admin/pauser/etc (list explicitly).

### Sale / Distribution
- Presale + Airdrop: parameters and addresses live in `docs/addresses.md`.
- **Claim Distributor (vesting):** **20% at TGE, then 10% every 15 days** until 100%.
- **Governance:** no timelock; **multisig** is the only proposer/executor for privileged ops.

### Invariants (must always hold)
- Total supply constant (or defined mint/burn policy).
- No unauthorized minting or draining of funds.
- Vesting math cannot overflow/underflow and respects cliffs.
- Whitelist/limits (if any) enforced as specified.
- **Only multisig (no timelock) can change critical params.**

### Upgradability & Admin
- If upgradeable, document proxy pattern and admin keys. If not upgradeable, state so explicitly.
- **Admin roles are held by multisig (no timelock).**
- Emergency pause: scope and conditions.

### Events
- Emit on state changes (mint/burn/pauses/role changes/claims).

### Gas & Denial of Service
- Avoid unbounded loops on user input.
- Claims and vesting scalable with large participant sets.


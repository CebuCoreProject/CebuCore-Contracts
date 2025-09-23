# CebuCore (CCORE) — Smart Contracts (Audit-Ready Repo)

**Status:** public, audit-ready skeleton (no secrets).  
**Network:** BNB Smart Chain (BSC) Mainnet.  
**Language/Tooling:** Solidity + Foundry (forge).

> ⚠️ Security First. This repo intentionally avoids any secrets, private keys, or production-only operational files. Do **not** commit `.env`, mnemonic/keystore files, RPC keys, Safe export bundles, or cloud configs. See `SECURITY.md` and `SAFETY_GUARDRAILS.md`.

---

## Public On-Chain References (BSC Mainnet)

- **CCORE Token (BEP-20):** `0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a`  
- **Treasury Safe (main):** `0xA0060Fd1CC044514D4E2F7D9F4204fEc517d7aDE`  
- **Revenue Safe (BNB):** `0x03AaA55404fE9b2090696AFE6fe185C5B320EEDe`

More details: see [`docs/addresses.md`](./docs/addresses.md).  
_Deprecated:_ `0xf55f608b4046E843625633FAA7371d6B3F3E50aB` — do not use.

---

## Presale Plan (summary)

- **Duration:** 10 days  
- **Min / Max buy:** 0.02 BNB / 20 BNB  
- **Rate:** **1 BNB = 1,000,000 CCORE**  
- **Vesting via Claim Distributor:** **20% at TGE, then 10% every 15 days** until 100%

Full parameters & notes: [`docs/presale.md`](./docs/presale.md).

---

## Token

- Fixed supply: **10,000,000,000 CCORE** (minted at genesis).  
- Transfers: standard ERC-20 semantics; anti-bot / limits if present (document exactly).  
- Roles: admin/pauser/etc (list explicitly).

---

## Governance

- **No timelock. Multisig-only** may execute privileged operations (admin/pauser/params).  
- Emergency pause: scope and conditions documented in code and `/docs`.

---

## Invariants (must always hold)

- Total supply constant (or defined mint/burn policy).  
- No unauthorized minting or draining of funds.  
- Vesting math cannot overflow/underflow and respects cliffs.  
- Whitelist/limits (if any) enforced as specified.  
- **Only multisig** can change critical parameters.

---

## Build & Verify

Compiler/target (must match deployed bytecode):
- `solc_version = 0.8.24`
- `optimizer = true`, `optimizer_runs = 200`
- `evm_version = shanghai` (BSC mainnet Paris/Shanghai)

```bash
# Build & sizes
forge clean && forge build --sizes

# Tests
forge test -vvv

# Verify example (BscScan)
forge verify-contract \
  --verifier bscscan --chain-id 56 \
  <DEPLOYED_ADDRESS> <FULLY_QUALIFIED_NAME> \
  --compiler-version v0.8.24+commit.e11b9ed9 \
  --num-of-optimizations 200 \
  --evm-version shanghai \
  --watch

---

## Quality checks (local)

```bash
# Lint
npx --yes solhint@4.x "contracts/**/*.sol"

# Slither (requires system solc 0.8.24)
python -m pip install --upgrade pip
pip install solc-select slither-analyzer
solc-select install 0.8.24 && solc-select use 0.8.24
slither . --fail-high --exclude-low --exclude-informational

contracts/        # production contracts (no secrets)
scripts/          # deploy/ops scripts (stateless)
test/             # Foundry tests
docs/             # addresses, presale, governance, invariants, threat model
security/         # audits (PDFs), policies
.github/          # CI workflows, issue/PR templates


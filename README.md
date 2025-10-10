# CebuCore (CCORE) — Smart Contracts (Audit-Ready Repo)

**Status:** public, audit-ready skeleton (no secrets).  
**Network:** BNB Smart Chain (BSC) Mainnet.  
**Language/Tooling:** Solidity + Foundry (forge).

> ⚠️ Security First. This repo intentionally avoids any secrets, private keys, or production-only operational files. Do **not** commit `.env`, mnemonic/keystore files, RPC keys, Safe export bundles, or cloud configs. See `SECURITY.md` and `SAFETY_GUARDRAILS.md`.

---

## Vesting & Distributors — BSC Mainnet (public, audit-ready)

> **Note.** All contracts are verified on BscScan. Deprecated address `0xf55f608b4046E843625633FAA7371d6B3F3E50aB` has been **removed**.

| Component | Address | Allocation | Cliff & Vesting | Beneficiary (receives tokens) |
|---|---|---:|---|---|
| **VESTING_TEAM_ADVISORS** | [`0x8ca790EE80d6fe7C94EB924Ee2Ec775aF4D9A75a`](https://bscscan.com/address/0x8ca790EE80d6fe7C94EB924Ee2Ec775aF4D9A75a) | **1.5B CCORE** | per schedule in docs | [`0xeF88eb9dA1493D0Cc9a18AfafA09F5EA99BC70cf`](https://bscscan.com/address/0xeF88eb9dA1493D0Cc9a18AfafA09F5EA99BC70cf) |
| **VESTING_PRIVATE_SALE** | [`0xCE8Eb1603F1a34637370938ed129C7E07c83cb8D`](https://bscscan.com/address/0xCE8Eb1603F1a34637370938ed129C7E07c83cb8D) | **1.0B CCORE** | per schedule in docs | [`0x18338629A6e109F5b07db7270Ce1Ce9FF7A7EccF`](https://bscscan.com/address/0x18338629A6e109F5b07db7270Ce1Ce9FF7A7EccF) |
| **VESTING_ECOSYSTEM** | [`0x083E2A30FEc95C798810075E5A36952794581444`](https://bscscan.com/address/0x083E2A30FEc95C798810075E5A36952794581444) | **2.0B CCORE** | **24m linear** | [`0x06e65FEb92280f1f9ed06D0833B441c72E66f1b7`](https://bscscan.com/address/0x06e65FEb92280f1f9ed06D0833B441c72E66f1b7) |
| **DISTRIBUTOR_SALE_AIRDROP** | [`0xE3E6404E849821AE981721990af5fFe9E9510127`](https://bscscan.com/address/0xE3E6404E849821AE981721990af5fFe9E9510127) | **0.5B + 0.5B CCORE** | **20% TGE, then 10% every 15 days** until 100% | — |
| **CEX & Market-Making Safe (Vesting)** | [`0x4703A70a991bd2021c7B4357b2697efce8916910`](https://bscscan.com/address/0x4703A70a991bd2021c7B4357b2697efce8916910) | per policy | **3 + 12 months** | [`0x66bf61E4dAAdc87e15B2c75A7ceA69963Cc5E234`](https://bscscan.com/address/0x66bf61E4dAAdc87e15B2c75A7ceA69963Cc5E234) |
| **Treasury Safe (Vesting)** | [`0x72a7422af5BAD5A9772CCCe94ee70d27a2141992`](https://bscscan.com/address/0x72a7422af5BAD5A9772CCCe94ee70d27a2141992) | per policy | per schedule in docs | [`0x0130c46Ec30DF64e7f430395F2d99E2C93A4c53D`](https://bscscan.com/address/0x0130c46Ec30DF64e7f430395F2d99E2C93A4c53D) |

---

## Public On-Chain References (BSC Mainnet)

- **CCORE Token (BEP-20):** [`0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a`](https://bscscan.com/address/0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a)  
- **Treasury Safe (main):** [`0xA0060Fd1CC044514D4E2F7D9F4204fEc517d7aDE`](https://bscscan.com/address/0xA0060Fd1CC044514D4E2F7D9F4204fEc517d7aDE)  
- **Revenue Safe (BNB):** [`0x03AaA55404fE9b2090696AFE6fe185C5B320EEDe`](https://bscscan.com/address/0x03AaA55404fE9b2090696AFE6fe185C5B320EEDe)

> See `docs/presale.md` for full vesting math/examples and `docs/addresses.md` for the complete list.


---



## Presale Plan (summary)

- **Duration:** 7 days  
- **Min / Max buy:** 0.05 BNB / 20 BNB  
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


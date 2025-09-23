# CebuCore (CCORE) — Smart Contracts (Audit-Ready Repo)
## Public On-Chain References (BSC Mainnet)

- **CCORE Token (BEP-20):** `0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a`
- **Treasury Safe (CCORE, main):** `0xA0060Fd1CC044514D4E2F7D9F4204fEc517d7aDE`
- **Revenue Safe (BNB):** `0x03AaA55404fE9b2090696AFE6fe185C5B320EEDe`

**Status:** public, audit-ready skeleton (no secrets).  
**Network:** BNB Smart Chain (BSC) Mainnet.  
**Language/Tooling:** Solidity 0.8.24 (fixed) + Hardhat/Foundry.

> ⚠️ **Security First.** This repo intentionally avoids any secrets, private keys, or production-only operational files. Do **not** commit `.env`, mnemonic/keystore files, RPC keys, Safe export bundles, or cloud configs. See [`docs/SAFETY_GUARDRAILS.md`](docs/SAFETY_GUARDRAILS.md).

---

## 1) What’s here
- **Contracts (prod sources):** ownerless vestings (fixed schedules) + ownerless Claim Distributor (no Merkle).
- **Tests & CI:** style + static analysis (Slither, Solhint) — to be extended.
- **Auditor docs:** invariants, threat model, on-chain refs, verification steps, checklist.

---

## 2) Public on-chain references (new token)
**Core**
- **CCORE Token (BEP-20)** — `0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a`

**Distribution / Vesting (new, ownerless)**
- **ClaimDistributor (Presale & Airdrop, 20% TGE + 8×10% / 15d)** — **TBD** (new address after deploy)
- **Vesting — Team & Advisors (1.5B, 6m cliff + 24m linear)** — **TBD**
- **Vesting — Private (1.0B, 6m cliff + 24m linear)** — **TBD**
- **Vesting — Ecosystem (2.0B, 24m linear from TGE)** — **TBD**
- **Vesting — CEX & MM (1.2B, 3m cliff + 12m linear)** — **TBD**
- **Vesting — Treasury (1.0B, 24m linear from TGE)** — **TBD**

**Safes**
- **Treasury Safe (Ops / Seeder for Distributor):** `0xA0060Fd1CC044514D4E2F7D9F4204fEc517d7aDE`
- **Team/Advisors Beneficiary:** `0xeF88eb9dA1493D0Cc9a18AfafA09F5EA99BC70cf`
- **Private Beneficiary:** `0x18338629A6e109F5b07db7270Ce1Ce9FF7A7EccF`
- **Ecosystem Beneficiary:** `0x06e65FEb92280f1f9ed06D0833B441c72E66f1b7`
- **CEX & MM Beneficiary:** `0x66bf61E4dAAdc87e15B2c75A7ceA69963Cc5E234`
- **Treasury Beneficiary:** `0x0130c46Ec30DF64e7f430395F2d99E2C93A4c53D`

> Keep this section in sync with `verifier/` inputs and any `constructor-args/` (if used). When each contract is deployed & verified, replace **TBD** with the address.

---

## 3) Presale (per plan)
- **Duration:** 10 days  
- **Min buy:** 0.02 BNB  
- **Max buy:** 20 BNB  
- **Initial rate:** 1000000 CCORE per 1 BNB  

## Governance

- **No timelock.**  
- **Multisig-only** can execute privileged operations (admin/pauser/param updates).  
- Emergency pause: scope & conditions documented in code and /docs.

**Vesting (ClaimDistributor):**  
- **Schedule:** **20% at TGE**, then **8 unlocks × 10% every 15 days** (total 100%).  
- **Distributor (new):** **TBD** (address after deploy).  
- **Tranches:** Presale — **500,000,000 CCORE**, Airdrop — **500,000,000 CCORE**.


## 4) Reproducible builds / verification
- All contracts use **`pragma solidity 0.8.24`**; optimizer **enabled, runs=200**.
- Document compiler config in [`docs/verification.md`](docs/verification.md).
- Verify sources on BscScan with the exact compiler settings used for deploy.

---

## 5) How to prepare for external audit
1. Ensure on-chain bytecode matches repo sources for each deployed contract.  
2. Complete docs in `docs/` (invariants, threat model, addresses, changelog).  
3. Ensure static analysis (Solhint/Slither) passes on a clean clone.  
4. Tag a read-only release (e.g., `audit-2025-10-01`).  
5. Share the repo URL + tag with auditors.

---
## Build & Verify

Compiler/target (must match deployed bytecode):
- `solc_version = 0.8.24`
- `optimizer = true`, `optimizer_runs = 200`
- `evm_version = shanghai` (BSC mainnet currently on Paris/Shanghai)

### Build
```bash
forge clean && forge build --sizes

---
forge test -vvv

forge verify-contract \
  --verifier bscscan \
  --chain-id 56 \
  <DEPLOYED_ADDRESS> <FULLY_QUALIFIED_NAME> \
  --compiler-version v0.8.24+commit.e11b9ed9 \
  --num-of-optimizations 200 \
  --evm-version shanghai \
  --watch


---

## 5) “Quality checks (local)” (того раздела у тебя не было)

```md
## Quality checks (local)

```bash
# Build & tests
forge clean && forge build --sizes
forge test -vvv

# Lint
npx --yes solhint@4.x "contracts/**/*.sol"

# Slither (system solc 0.8.24 is required)
pip install --upgrade pip
pip install solc-select slither-analyzer
solc-select install 0.8.24 && solc-select use 0.8.24
slither . --fail-high --exclude-low --exclude-informational


---

## 6) “Security & Disclosure” (коротко, обязательно)

```md
## Security & Disclosure

- No private keys, mnemonics, RPC keys, or secrets in this repo.  
- For vulnerability disclosure, contact: **security@cebucore.com** (PGP optional).  
- See `SECURITY.md` and `SAFETY_GUARDRAILS.md` for details.

## Invariants (must always hold)

- Total supply constant (or defined mint/burn policy).  
- No unauthorized minting or draining of funds.  
- Vesting math cannot overflow/underflow and respects cliffs.  
- Whitelist/limits (if any) enforced as specified.  
- **Only multisig** can change critical parameters.
docs(readme): add on-chain refs, presale plan, governance (no timelock), build/verify, quality checks, security; update invariants


## 7) Contacts & Official links
- Website: https://cebucore.com  
- GitHub: https://github.com/CebuCoreProject

- X (Twitter): https://x.com/CebuCore  
- Telegram — Announcements: https://t.me/CebuCoreNews  
- Telegram — Support:      https://t.me/CebuCore_Chat  
- Discord:  https://discord.gg/A2b45cGNMp  

- Email (general): contact@cebucore.com  
- Email (security): cebu.core.project@gmail.com

> Only the links above are official. We never DM first or ask for seed phrases. Airdrop/presale links are announced on the website and the **Announcements** channel only.

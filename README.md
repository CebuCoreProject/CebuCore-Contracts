
# CebuCore (CCR) — Smart Contracts (Audit‑Ready Repo)

**Status:** public, audit‑ready skeleton (no secrets).  
**Network:** BNB Smart Chain (BSC) Mainnet.  
**Language/Tooling:** Solidity + Foundry (forge).

> ⚠️ **Security First.** This repo intentionally avoids any secrets, private keys, or production‑only operational files. Do **not** commit `.env`, mnemonic/keystore files, RPC keys, Safe export bundles, or cloud configs. See [`docs/SAFETY_GUARDRAILS.md`](docs/SAFETY_GUARDRAILS.md).

## 1) What’s here
- Contracts (placeholders): replace with the **actual** production sources before you tag a release or send to auditors.
- Tests skeleton and CI to enforce build, style and static analysis (Slither, Solhint).
- Documentation for auditors: invariants, threat model, addresses, verification steps, and audit checklist.

## 2) Public on‑chain references (as of 2025‑09‑01)
- **CCR token:** `0x422f097BB0Fc9d2adEb619349dB8df6a2450bbc6`
- **Treasury Safe (CCR):** `0xf55f608b4046E843625633FAA7371d6B3F3E50aB`
- **Revenue Safe (BNB):** `0x03AaA55404fE9b2090696AFE6fe185C5B320EEDe`
- **Timelock (48h):** `0x546D6fd8fA0945eDE494565158d9775f6492575E`

Presale (per plan):
- Duration: 30 days
- Min buy: 0.02 BNB
- Max buy: 50 BNB
- Initial rate: 85,000 CCR per 1 BNB
- Vesting (Claim Distributor): 4×25% at TGE/+30/+60/+90 days
- Tranches: Presale 500M, Airdrop 500M

> If these change, update [`docs/addresses.md`](docs/addresses.md) and commit.

## 3) Quick start (Foundry)
```bash
# 1) Install foundry (if needed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 2) Clone and prepare
git clone <YOUR_REPO_URL>.git cebucore-contracts
cd cebucore-contracts

# 3) Install libraries
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2

# 4) Build & test
forge fmt --check
forge build
forge test -vvv

# 5) (Optional) Static analysis
npm i -D solhint
npx solhint 'contracts/**/*.sol'

# Slither (requires Python)
pip install slither-analyzer==0.10.4
slither .
```

## 4) Reproducible builds / verification
- Set exact `solc_version` and optimizer settings in `foundry.toml` to match deployed contracts.
- Document compiler config in [`docs/verification.md`](docs/verification.md).
- Verify sources on BscScan manually or via scripts (no API keys in repo).

## 5) How to prepare for external audit
1. Replace placeholders with **your actual contracts** (make sure they match on‑chain bytecode if already deployed).  
2. Complete docs in `docs/` (invariants, threat model, addresses, changelog).  
3. Ensure CI passes on a clean clone.  
4. Tag a read‑only release (e.g., `audit-2025-09-01`).  
5. Share the repo URL + tag with auditors.

## 6) License & disclosures
- Default license: MIT (change if needed).  
- See `DISCLAIMER.md` — this is **not** investment advice.

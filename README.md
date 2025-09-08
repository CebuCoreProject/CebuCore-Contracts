
# CebuCore (CCR) — Smart Contracts (Audit‑Ready Repo)

**Status:** public, audit‑ready skeleton (no secrets).  
**Network:** BNB Smart Chain (BSC) Mainnet.  
**Language/Tooling:** Solidity + Foundry (forge).

> ⚠️ **Security First.** This repo intentionally avoids any secrets, private keys, or production‑only operational files. Do **not** commit `.env`, mnemonic/keystore files, RPC keys, Safe export bundles, or cloud configs. See [`docs/SAFETY_GUARDRAILS.md`](docs/SAFETY_GUARDRAILS.md).

## What’s here
- **Contracts** (prod sources): replace any placeholders before tagging a release or sending to auditors.
- **Tests & CI**: build + style + static analysis (Slither, Solhint).
- **Auditor docs**: invariants, threat model, on-chain refs, verification steps, checklist.

## Public on-chain references (as of 2025-09-08)
**Core**
- CCR Token — `0x422f097BB0Fc9d2adEb619349dB8df6a2450bbc6`

**Distribution / Vesting**
- ClaimDistributor (Presale & Airdrop) — `0x696E0E6e55133fD205812dbD8e1DeDbaD266F127`
- Vesting — Team/Advisors — `0xb829e2c0b8d08a025a915C163Da77Fa234B72e7b`
- Vesting — Private — `0x8b27d9a5C33eAa16537335acd62819BF12F60413`
- Vesting — Ecosystem (24m linear) — `0x29ca47A1ddfDbB2662a99634Bc5Aa3204f5185ac`
- CEX & Market-Making Safe (Vesting 3+9) — `0xd66D8518d80D9D8dBED328E1E236196541135B17`

**Safes / Treasury**
- Treasury Safe (Vesting) — `0xf55f608b4046E843625633FAA7371d6B3F3E50aB`
- Treasury Safe (Ops) — `0xA0060Fd1CC044514D4E2F7D9F4204fEc517d7aDE`
- Revenue Safe (BNB) — `0x03AaA55404fE9b2090696AFE6fe185C5B320EEDe`

**Governance**
- Timelock (48h) — `0x546D6fd8fA0945eDE494565158d9775f6492575E`

> Keep this section in sync with `verifier/` inputs and `constructor-args/` files.

## Presale (per plan)
- **Duration:** 30 days  
- **Min buy:** 0.02 BNB  
- **Max buy:** 50 BNB  
- **Initial rate:** 85,000 CCR per 1 BNB  

**Vesting (ClaimDistributor):**  
- **New schedule:** **20% at TGE**, then **8 unlocks × 10% every 15 days** (total 100%).  
- **Distributor contract:** `0x696E0E6e55133fD205812dbD8e1DeDbaD266F127`.

**Tranches (via ClaimDistributor):**
- Presale — **500,000,000 CCR**  
- Airdrop — **500,000,000 CCR**


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

## 6) License & Disclosures

### License
This repository is licensed under the MIT License.  
See [`LICENSE`](./LICENSE). Each Solidity file includes an SPDX header.

### Disclosures
- **No investment advice.** CCR is a utility token; it does not represent equity, profits, or governance rights.
- **Jurisdictions.** Access may be restricted where token offerings are limited or sanctioned by law.
- **Smart-contract risk.** Audits/KYC reduce but do not eliminate risk. On-chain interactions are irreversible; funds can be lost.
- **Upgradability & controls.** Contracts include admin/timelock controls (48h timelock at `0x546D6f…575E`). Parameters may change only via authorized roles/timelock; see `AUDIT_SCOPE.md`.
- **Presale vesting.** **20% at TGE, then 10% every 15 days ×8** via ClaimDistributor `0x696E0E…F127`. Tranches: Presale 500M, Airdrop 500M.
- **Referral.** 5% in CCR for verified presale invites per program rules; no self-referrals or multi-account abuse.
- **Airdrop.** Subject to eligibility/KYC/anti-abuse; distribution and dates may change; excluded jurisdictions apply.

For security issues, please follow [`SECURITY.md`](./SECURITY.md) and do not open public issues for sensitive findings.

- Default license: MIT (change if needed).  
- See `DISCLAIMER.md` — this is **not** investment advice.

## 7) Architecture & invariants
- **Token (CCR)** — deflationless ERC20; pausable; no hidden mint/burn beyond declared rules.
- **ClaimDistributor** — Merkle-less allowlist with owner-set allocations; schedule: 20% TGE + 8×10% every 15 days.
- **Vesting safes** — linear or stepped releases; funds move only to whitelisted sinks.
- **Treasury/Revenue safes** — custody only; no arbitrary minting; outflows require owner/threshold policies.
- **Invariants**
  - Total CCR held by distributors + circulating ≤ max supply.
  - No role can bypass timelock for sensitive ops.
  - Pausing blocks transfers where specified, not mint/burn accounting.

## 8) Roles & permissions
| Role / Control                | Holder / Mechanism | Scope |
|------------------------------|--------------------|------|
| `DEFAULT_ADMIN_ROLE`         | **Timelock 48h** `0x546D6fd8fA0945eDE494565158d9775f6492575E` | Admin changes, critical params |
| `PAUSER_ROLE`                | Core ops via timelock | Pause/unpause token if emergency |
| Distributor Owner            | Timelock → Distributor | Set allocations, start TGE/schedule |
| Vesting Admin                | Timelock → Vesting contracts | Configure schedules (where allowed) |
| Safe Owners / Threshold      | Gnosis/Multisig or equivalent | Treasury/Revenue outflows |

> Любое изменение прав/ключевых параметров проходит через timelock (48h).

## 9) Upgradability & emergency
- **Upgradeability:** no proxies unless explicitly stated in the contract path. On-chain code is immutable; only params via roles/timelock.
- **Emergency:** `pause()` (where available), timelock-gated revocation/halts, safes stop outflows by policy.

## 10) Verification artifacts (mapping)
| Component | Address | Source path | Compiler JSON | Constructor args |
|---|---|---|---|---|
| CCR Token | `0x422f097BB0Fc9d2adEb619349dB8df6a2450bbc6` | `contracts/CebuCoreToken.sol` | `verifier/token-0x422f097B....json` | `constructor-args/0x422f097B....txt` |
| ClaimDistributor (Presale/Airdrop) | `0x696E0E6e55133fD205812dbD8e1DeDbaD266F127` | `contracts/distributor/ClaimDistributor.sol` | `verifier/distributor-0x696E0E6e....json` | `constructor-args/0x696E0E6e....txt` |
| Vesting — Team/Advisors | `0xb829e2c0b8d08a025a915C163Da77Fa234B72e7b` | `contracts/vesting/TeamAdvisorsVesting.sol` | `verifier/vesting-team-0xb829e2c0....json` | `constructor-args/0xb829e2c0....txt` |
| Vesting — Private | `0x8b27d9a5C33eAa16537335acd62819BF12F60413` | `contracts/vesting/PrivateVesting.sol` | `verifier/vesting-private-0x8b27d9a5....json` | `constructor-args/0x8b27d9a5....txt` |
| Vesting — Ecosystem (24m) | `0x29ca47A1ddfDbB2662a99634Bc5Aa3204f5185ac` | `contracts/vesting/EcosystemVesting.sol` | `verifier/vesting-eco-0x29ca47A1....json` | `constructor-args/0x29ca47A1....txt` |
| CEX/MM Safe (3+9) | `0xd66D8518d80D9D8dBED328E1E236196541135B17` | `contracts/vesting/CexMmSafe.sol` | `verifier/cexmm-0xd66D8518....json` | `constructor-args/0xd66D8518....txt` |
| Treasury Safe (Vesting) | `0xf55f608b4046E843625633FAA7371d6B3F3E50aB` | `contracts/vesting/TreasurySafeVesting.sol` | `verifier/treasury-0xf55f608b....json` | `constructor-args/0xf55f608b....txt` |
| Treasury Safe (Ops) | `0xA0060Fd1CC044514D4E2F7D9F4204fEc517d7aDE` | `contracts/safes/TreasurySafe.sol` | `verifier/treasury-ops-0xA0060Fd1....json` | `constructor-args/0xA0060Fd1....txt` |
| Revenue Safe (BNB) | `0x03AaA55404fE9b2090696AFE6fe185C5B320EEDe` | `contracts/safes/RevenueSafe.sol` | `verifier/revenue-0x03AaA554....json` | `constructor-args/0x03AaA554....txt` |

> Подстрой пути `verifier/*.json`/`constructor-args/*.txt` под твои реальные имена файлов.

## 11) Tests, coverage & CI
```bash
# Unit tests
forge test -vvv

# Gas snapshots (optional)
forge snapshot

# Coverage (если установлен forge-coverage)
forge coverage --report lcov

## 12) Contacts & Official links
- Website: https://cebucore.com
- Docs:   https://docs.cebucore.com
- GitHub: https://github.com/CebuCoreProject

- X (Twitter): https://x.com/CebuCore
- Telegram — Announcements: https://t.me/CebuCoreNews
- Telegram — Support:       https://t.me/CebuCoreSupport
- Discord:  https://discord.gg/A2b45cGNMp

- Email cebu.core.project@gmail.com

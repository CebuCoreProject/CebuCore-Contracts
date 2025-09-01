
# Threat Model (STRIDE‑lite)

**Assets:** CCR token supply, presale funds, treasury & revenue Safes, claim balances, admin authority.

**Actors:** Users, investors, multisig signers, timelock proposer/executor, potential attackers (arbitrage, MEV, bots).

**Key risks:**
- Unauthorized mint/burn or balance manipulation
- Vesting/claim math errors
- Role misconfiguration bypassing timelock
- Reentrancy or approval misuse
- Denial of service via unbounded loops or gas griefing
- Flash‑loan manipulation if using price oracles (document if applicable)

**Mitigations:** rigorous role gating, timelock + multisig, bounded loops, checks‑effects‑interactions, pausable scope (clearly defined), extensive tests & static analysis.

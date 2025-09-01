
# Audit Handoff Checklist

- [ ] **Sources complete** and match on‑chain bytecode.
- [ ] **Exact compiler config** documented (`foundry.toml`).
- [ ] **No secrets** or private operational files committed.
- [ ] **Invariants** and **threat model** documented.
- [ ] **Addresses/params** documented and up to date.
- [ ] **Tests** run green on clean clone (`forge test`).
- [ ] **Static analysis** runs without critical findings (Slither/Solhint).
- [ ] **Release tag** created (e.g., `audit-YYYY-MM-DD`), code freeze.
- [ ] **Branch protection** and required checks enabled on `main`.
- [ ] **Responsible disclosure** contact in `SECURITY.md`.

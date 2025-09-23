# Safety Guardrails

- No private keys, mnemonics, RPC keys, Safe exports, or cloud configs in this repo.
- Only Solidity sources, ABIs, docs, and verification artifacts.
- Secrets live in secure vaults (not Git).
- Before tagging a release: verify all deployed contracts on BscScan and update `docs/addresses.md`.
- After finishing edits, re-enable branch protection on `main`.


# Verification & Reproducible Build

## Compiler
- `solc_version`: **set in foundry.toml** (must match deployed/verified contract).
- `optimizer`: `true`, runs `200` (adjust if production differs).
- `evm_version`: set to match BSC deployment target (London/Shanghai).

## Steps
1. Ensure repo clean: `forge fmt --check && forge build`.
2. Export flattened sources if your verifier requires (BscScan supports multi‑file).
3. Verify on BscScan with exact compiler/optimizer settings.
4. Compare bytecode & metadata hash with on‑chain contract.
5. Commit a short `docs/verification.md` update with the verification URL.

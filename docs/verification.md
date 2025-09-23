# Verification notes

Compiler: `solc 0.8.24`  
Optimizer: `enabled = true`, `runs = 200`  
EVM: `cancun` (or default)

Verify each contract on BscScan with the exact settings above.
- Vestings: no constructor args.
- ClaimDistributor: no constructor args.
- All addresses/timestamps are hard-coded constants. Bytecode must match.

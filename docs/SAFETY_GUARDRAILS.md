
# Safety Guardrails — What **NOT** to push

**Never commit:**
- Private keys, mnemonics, keystore files, seed phrases
- `.env` files with RPC or API secrets (BscScan, Alchemy, etc.)
- Gnosis Safe exports / transaction bundles
- Server/cloud configs, IPs, deployment scripts with real endpoints
- Internal dashboards, logs, or user data

**Prefer separate private repos** for operations (runbooks, infra, Safe workflows).  
Public repo = **code & docs needed for audit only**.

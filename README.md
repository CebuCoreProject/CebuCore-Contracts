# CebuCore (CCR) — Smart Contracts (Audit-Ready Repo)

[![CI](https://github.com/CebuCoreProject/CebuCore-Contracts/actions/workflows/ci.yml/badge.svg)](https://github.com/CebuCoreProject/CebuCore-Contracts/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](/LICENSE)
![Solidity](https://img.shields.io/badge/Solidity-%3E%3D0.8.26-363636)

Audit-ready smart contracts for CebuCore (CCR).  
No secrets. Deterministic builds. CI: Foundry + Solhint + Slither.  
Network: **BNB Smart Chain (BSC)** mainnet.

---

## Contents

- [`contracts/`](./contracts) — CCR contracts  
- [`docs/`](./docs) — addresses, spec, verification, audit checklist  
- [`security/`](./security) — threat model & report template  
- CI: `.github/workflows/ci.yml` (format/test/lint/analyze)

> ❗ На данный момент в репозитории размещён **минимальный placeholder-контракт** — реальный код токена/логики будет добавлен отдельным PR перед аудитом. Репозиторий уже настроен и защищён для безопасного процесса разработки.

---

## Quickstart

### Requirements
- `foundryup` (Foundry) — https://book.getfoundry.sh  
- `node` ≥ 18 (для solhint)  
- (опционально) `python3 -m pip install slither-analyzer`  

```bash
# 1) Установить/обновить Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 2) Установить npm зависимости для линтера (локально)
npm i -D solhint @solhint/config

# 3) Скопировать локальные переменные
cp .env.example .env
# Заполнить .env своими значениями (локально, НЕ коммитить!)

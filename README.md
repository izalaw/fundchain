# FundChain: Protocolo Descentralizado de Crowdfunding

Protocolo Web3 para financiamento coletivo de pequenos negocios de tecnologia e inovacao.

Desenvolvido como projeto final da Unidade 1, Capitulo 5, da Residencia em TIC 29 (Web 3.0).

## Problema

Pequenos negocios de tecnologia e inovacao enfrentam barreiras para acessar financiamento. Bancos exigem garantias que empreendedores em estagio inicial nao possuem. Plataformas centralizadas de crowdfunding cobram taxas elevadas e nao oferecem transparencia nem participacao aos apoiadores.

## Solucao

Uma plataforma descentralizada onde empreendedores submetem projetos, apoiadores contribuem com tokens, recebem certificados (NFTs) e participam das decisoes por meio de governanca on-chain (DAO).

## Arquitetura

O protocolo e composto por 4 contratos inteligentes:

| Contrato | Padrao | Funcao |
|----------|--------|--------|
| FundToken | ERC-20 | Moeda da plataforma (compra, staking, votacao) |
| FundNFT | ERC-721 | Certificado unico de apoiador |
| FundStaking | Custom | Staking com recompensa ajustada por oraculo Chainlink |
| FundDAO | Custom | Governanca descentralizada (criar/votar propostas) |

## Fluxo

1. Empreendedor submete projeto
2. DAO vota pela aprovacao
3. Apoiadores compram FundTokens e apoiam o projeto
4. Apoiadores recebem NFT como certificado
5. Tokens podem ser travados no staking para gerar recompensas
6. Detentores de tokens votam nas decisoes da plataforma

## Tecnologias
- Solidity ^0.8.x, compilado com 0.8.26
- OpenZeppelin Contracts
- Chainlink Price Feed (ETH/USD)
- Hardhat (compilacao, testes, deploy)
- ethers.js (integracao Web3)
- Sepolia Testnet

## Estrutura do Projeto

```
contracts/
  FundToken.sol       # Token ERC-20
  FundNFT.sol         # NFT ERC-721
  FundStaking.sol     # Staking + oraculo Chainlink
  FundDAO.sol         # Governanca (DAO)
scripts/
  deploy.cjs          # Script de deploy na Sepolia
  interact.cjs        # Demonstracao: mint NFT, stake, votacao
hardhat.config.js     # Configuracao do Hardhat

README.md             # Este arquivo
```

## Seguranca

- ReentrancyGuard (OpenZeppelin) no contrato de staking
- Ownable (OpenZeppelin) em todos os contratos
- Solidity ^0.8.x, compilado com 0.8.26, com protecao nativa contra 
overflow/underflow
- Validacoes com require() em todas as funcoes
- Auditoria com Slither e Mythril

## Deploy (Sepolia Testnet)

| Contrato | Endereco |
|----------|----------|
| FundToken | 0xF5388311F36836aC261c3f5Ca9f92834Dec096b1 |
| FundNFT | 0x5f644F47A063ee20275c674Dd298D505184966F8 |
| FundStaking | 0xa4350e9A644dFC3B40Ba138BeAf82aB2bB66574F |
| FundDAO | 0x27938F70e4b7BcCB3A1921CBCf9DbCb0e57aB9D1 |

Chainlink ETH/USD Price Feed (Sepolia): `0x694AA1769357215DE4FAC081bf1f309aDC325306`

## Como Executar

### Requisitos
- Node.js v18+
- MetaMask com ETH de teste na Sepolia

### Instalacao

```bash
git clone https://github.com/seu-usuario/fundchain.git
cd fundchain
npm install
```

### Compilar

```bash
npx hardhat compile
```

### Testar

```bash
npx hardhat test
```

### Deploy na Sepolia

```bash
npx hardhat run scripts/deploy.cjs --network sepolia
```

### Interagir com os contratos

```bash
npx hardhat run scripts/interact.cjs --network sepolia
```

## Autora

Izabela Fernandes

Residencia em TIC 29 - Web 3.0 | Prof. Bruno Portes

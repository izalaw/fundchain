// scripts/interact.js
// Script de integracao Web3 demonstrando: Mint de NFT, Stake de tokens e Votacao na DAO
// Execucao: npx hardhat run scripts/interact.js --network sepolia

const hre = require("hardhat");

// IMPORTANTE: Substitua esses enderecos pelos enderecos reais apos o deploy
const FUND_TOKEN_ADDRESS = "0xF5388311F36836aC261c3f5Ca9f92834Dec096b1";
const FUND_NFT_ADDRESS = "0x5f644F47A063ee20275c674Dd298D505184966F8";
const FUND_STAKING_ADDRESS = "0xa4350e9A644dFC3B40Ba138BeAf82aB2bB66574F";
const FUND_DAO_ADDRESS = "0x27938F70e4b7BcCB3A1921CBCf9DbCb0e57aB9D1";

async function main() {
    const [account] = await hre.ethers.getSigners();
    console.log("Conta utilizada:", account.address);
    console.log("===\n");

    // Conectar aos contratos
    const fundToken = await hre.ethers.getContractAt("FundToken", FUND_TOKEN_ADDRESS);
    const fundNFT = await hre.ethers.getContractAt("FundNFT", FUND_NFT_ADDRESS);
    const fundStaking = await hre.ethers.getContractAt("FundStaking", FUND_STAKING_ADDRESS);
    const fundDAO = await hre.ethers.getContractAt("FundDAO", FUND_DAO_ADDRESS);

    // =====================================================================
    // 1. MINT DE NFT
    // Demonstra a emissao de um certificado de apoiador
    // =====================================================================
    console.log("1. MINT DE NFT (Certificado de Apoiador)");
    console.log("   Emitindo certificado...");

    const txNFT = await fundNFT.emitirCertificado(
        account.address,
        "Startup InovaTech",
        hre.ethers.parseEther("500") // 500 tokens de apoio
    );
    await txNFT.wait();

    const totalNFTs = await fundNFT.totalEmitidos();
    console.log("   Certificado emitido com sucesso!");
    console.log("   Total de NFTs emitidos:", totalNFTs.toString());

    // Consultar dados do certificado
    const cert = await fundNFT.consultarCertificado(0);
    console.log("   Projeto:", cert.nomeProjeto);
    console.log("   Apoiador:", cert.apoiador);
    console.log("   Valor do apoio:", hre.ethers.formatEther(cert.valorApoio), "tokens");
    console.log("");

    // =====================================================================
    // 2. STAKE DE TOKENS
    // Demonstra o processo de aprovacao e staking de tokens
    // =====================================================================
    console.log("2. STAKE DE TOKENS");

    const stakeAmount = hre.ethers.parseEther("1000"); // 1000 tokens

    // Primeiro: aprovar o contrato de staking para movimentar os tokens
    console.log("   Aprovando contrato de staking...");
    const txApprove = await fundToken.approve(FUND_STAKING_ADDRESS, stakeAmount);
    await txApprove.wait();
    console.log("   Aprovacao concluida.");

    // Segundo: realizar o stake
    console.log("   Realizando stake de 1000 tokens...");
    const txStake = await fundStaking.stake(stakeAmount);
    await txStake.wait();

    const saldo = await fundStaking.saldoEmStake(account.address);
    console.log("   Stake concluido!");
    console.log("   Saldo em stake:", hre.ethers.formatEther(saldo), "tokens");
    console.log("");

    // =====================================================================
    // 3. VOTACAO NA DAO
    // Demonstra a criacao de proposta e registro de voto
    // =====================================================================
    console.log("3. VOTACAO NA DAO");

    // Criar proposta
    console.log("   Criando proposta...");
    const txProposta = await fundDAO.criarProposta(
        "Aprovar financiamento de R$ 50.000 para o projeto Inovatech, startup de IA voltada a educacao"
    );
    await txProposta.wait();

    const totalPropostas = await fundDAO.totalPropostas();
    const propostaId = totalPropostas - 1n;
    console.log("   Proposta criada! ID:", propostaId.toString());

    // Consultar proposta
    const proposta = await fundDAO.consultarProposta(propostaId);
    console.log("   Descricao:", proposta.descricao);

    // Votar a favor
    console.log("   Registrando voto a favor...");
    const txVoto = await fundDAO.votar(propostaId, true);
    await txVoto.wait();
    console.log("   Voto registrado com sucesso!");

    // Consultar resultado parcial
    const propostaAtualizada = await fundDAO.consultarProposta(propostaId);
    console.log("   Votos a favor:", hre.ethers.formatEther(propostaAtualizada.votosAFavor));
    console.log("   Votos contra:", hre.ethers.formatEther(propostaAtualizada.votosContra));

    const aberta = await fundDAO.votacaoAberta(propostaId);
    console.log("   Votacao aberta:", aberta);
    console.log("");

    // =====================================================================
    // RESUMO
    // =====================================================================
    console.log("=== DEMONSTRACAO CONCLUIDA ===");
    console.log("NFT mintado, tokens em stake e voto registrado com sucesso.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

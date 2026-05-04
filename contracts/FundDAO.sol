// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============================================================================
// FUNDDAO — Contrato de Governanca Descentralizada (DAO simplificada)
// =============================================================================
//
// Este contrato implementa um mecanismo basico de governanca onde os
// detentores de FundToken podem criar propostas e votar nelas. Funciona
// como uma assembleia digital: qualquer detentor de tokens pode propor
// decisoes (ex: aprovar um projeto, alterar regras da plataforma), e os
// demais votam sim ou nao. Se a proposta atingir o quorum minimo e tiver
// maioria de votos a favor, ela e aprovada.
//
// O poder de voto e baseado na quantidade de tokens que o usuario possui
// no momento da votacao: 1 token = 1 voto.
//
// SEGURANCA:
// - Cada endereco so pode votar uma vez por proposta
// - Propostas tem prazo de votacao (nao ficam abertas pra sempre)
// - Apenas o admin pode executar propostas aprovadas
// =============================================================================

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title FundDAO
/// @notice Governanca simplificada para a plataforma de crowdfunding

contract FundDAO is Ownable {

    // Token usado para votacao (1 token = 1 voto)
    IERC20 public fundToken;

    // Duracao padrao de votacao (3 dias em segundos)
    uint256 public duracaoVotacao = 3 days;

    // Quorum minimo: porcentagem de tokens que precisa votar (10%)
    uint256 public quorumMinimo = 10;

    // Contador de propostas
    uint256 public totalPropostas;

    // Estrutura de uma proposta
    struct Proposta {
        string descricao;         // O que esta sendo proposto
        address proponente;       // Quem criou a proposta
        uint256 votosAFavor;      // Total de votos sim
        uint256 votosContra;      // Total de votos nao
        uint256 prazoFinal;       // Timestamp limite para votar
        bool executada;           // Se a proposta ja foi executada
        bool aprovada;            // Se foi aprovada
    }

    // Mapping de ID para proposta
    mapping(uint256 => Proposta) public propostas;

    // Mapping duplo: propostaId => endereco => ja votou?
    mapping(uint256 => mapping(address => bool)) public jaVotou;

    // Eventos
    event PropostaCriada(
        uint256 indexed propostaId,
        address indexed proponente,
        string descricao,
        uint256 prazoFinal
    );

    event VotoRegistrado(
        uint256 indexed propostaId,
        address indexed votante,
        bool aFavor,
        uint256 pesoVoto
    );

    event PropostaExecutada(
        uint256 indexed propostaId,
        bool aprovada
    );

    /// @notice Constructor: recebe o endereco do FundToken
    /// @param _fundToken Endereco do contrato FundToken
    constructor(address _fundToken) Ownable(msg.sender) {
        require(_fundToken != address(0), "Endereco do token invalido");
        fundToken = IERC20(_fundToken);
    }

    /// @notice Cria uma nova proposta
    /// @param _descricao Texto descrevendo a proposta
    /// @dev Qualquer detentor de tokens pode criar uma proposta
    function criarProposta(string memory _descricao) external returns (uint256) {
        // Precisa ter tokens para criar proposta
        require(
            fundToken.balanceOf(msg.sender) > 0,
            "Precisa ter tokens para criar proposta"
        );
        require(bytes(_descricao).length > 0, "Descricao vazia");

        uint256 propostaId = totalPropostas;
        totalPropostas++;

        propostas[propostaId] = Proposta({
            descricao: _descricao,
            proponente: msg.sender,
            votosAFavor: 0,
            votosContra: 0,
            prazoFinal: block.timestamp + duracaoVotacao,
            executada: false,
            aprovada: false
        });

        emit PropostaCriada(propostaId, msg.sender, _descricao, block.timestamp + duracaoVotacao);

        return propostaId;
    }

    /// @notice Registra um voto em uma proposta
    /// @param _propostaId ID da proposta
    /// @param _aFavor true para votar sim, false para votar nao
    function votar(uint256 _propostaId, bool _aFavor) external {
        Proposta storage p = propostas[_propostaId];

        // Validacoes de seguranca
        require(block.timestamp <= p.prazoFinal, "Votacao encerrada");
        require(!p.executada, "Proposta ja executada");
        require(!jaVotou[_propostaId][msg.sender], "Ja votou nesta proposta");

        // Peso do voto = saldo de tokens do votante
        uint256 pesoVoto = fundToken.balanceOf(msg.sender);
        require(pesoVoto > 0, "Precisa ter tokens para votar");

        // Registra o voto
        jaVotou[_propostaId][msg.sender] = true;

        if (_aFavor) {
            p.votosAFavor += pesoVoto;
        } else {
            p.votosContra += pesoVoto;
        }

        emit VotoRegistrado(_propostaId, msg.sender, _aFavor, pesoVoto);
    }

    /// @notice Executa uma proposta apos o prazo de votacao
    /// @param _propostaId ID da proposta
    /// @dev Apenas o admin pode executar. Verifica quorum e maioria.
    function executarProposta(uint256 _propostaId) external onlyOwner {
        Proposta storage p = propostas[_propostaId];

        require(block.timestamp > p.prazoFinal, "Votacao ainda em andamento");
        require(!p.executada, "Proposta ja executada");

        // Calcula quorum: total de votos / total de tokens em circulacao
        uint256 totalVotos = p.votosAFavor + p.votosContra;
        uint256 totalSupply = fundToken.totalSupply();
        uint256 participacao = (totalVotos * 100) / totalSupply;

        // Verifica quorum minimo
        require(participacao >= quorumMinimo, "Quorum minimo nao atingido");

        // Marca como executada
        p.executada = true;

        // Aprovada se maioria votou a favor
        if (p.votosAFavor > p.votosContra) {
            p.aprovada = true;
        }

        emit PropostaExecutada(_propostaId, p.aprovada);
    }

    /// @notice Consulta detalhes de uma proposta
    /// @param _propostaId ID da proposta
    function consultarProposta(uint256 _propostaId)
        external
        view
        returns (
            string memory descricao,
            address proponente,
            uint256 votosAFavor,
            uint256 votosContra,
            uint256 prazoFinal,
            bool executada,
            bool aprovada
        )
    {
        Proposta memory p = propostas[_propostaId];
        return (
            p.descricao,
            p.proponente,
            p.votosAFavor,
            p.votosContra,
            p.prazoFinal,
            p.executada,
            p.aprovada
        );
    }

    /// @notice Verifica se a votacao de uma proposta ainda esta aberta
    function votacaoAberta(uint256 _propostaId) external view returns (bool) {
        return block.timestamp <= propostas[_propostaId].prazoFinal
            && !propostas[_propostaId].executada;
    }

    /// @notice Permite ao admin alterar a duracao da votacao
    function setDuracaoVotacao(uint256 _novaDuracao) external onlyOwner {
        require(_novaDuracao > 0, "Duracao deve ser maior que zero");
        duracaoVotacao = _novaDuracao;
    }

    /// @notice Permite ao admin alterar o quorum minimo
    function setQuorumMinimo(uint256 _novoQuorum) external onlyOwner {
        require(_novoQuorum > 0 && _novoQuorum <= 100, "Quorum invalido");
        quorumMinimo = _novoQuorum;
    }
}

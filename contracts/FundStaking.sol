// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============================================================================
// FUNDSTAKING — Contrato de Staking com integracao de oraculo Chainlink
// =============================================================================
//
// Este contrato permite que apoiadores travem (stake) seus FundTokens e
// recebam recompensas ao longo do tempo. A recompensa e ajustada
// dinamicamente com base no preco do ETH/USD obtido via oraculo Chainlink.
//
// ORACULO:
// Oraculos sao servicos que trazem dados do mundo real para dentro da
// blockchain. A blockchain, por si so, nao consegue acessar APIs externas
// ou dados fora da rede. O Chainlink resolve isso de forma descentralizada
// e confiavel. Aqui, usamos o price feed ETH/USD para ajustar a recompensa:
// quando o ETH esta mais caro, a recompensa em tokens e menor; quando
// esta mais barato, a recompensa e maior.
//
// SEGURANCA:
// - ReentrancyGuard: protege contra ataques de reentrancy, onde um contrato
//   malicioso tenta chamar a funcao de saque repetidamente antes que o saldo
//   seja atualizado.
// - Ownable: garante que apenas o admin execute funcoes administrativas.
// =============================================================================

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title FundStaking
/// @notice Staking de FundTokens com recompensa ajustada por oraculo Chainlink

contract FundStaking is ReentrancyGuard, Ownable {

    // Token ERC-20 usado no staking
    IERC20 public fundToken;

    // Oraculo Chainlink para preco ETH/USD
    AggregatorV3Interface public priceFeed;

    // Taxa base de recompensa (tokens por segundo por token em stake, x10^18)
    uint256 public taxaRecompensa = 100;

    // Estrutura dos dados de cada staker
    struct Staker {
        uint256 saldoStake;        // Quantidade de tokens em stake
        uint256 recompensaAcumulada; // Recompensa pendente
        uint256 ultimaAtualizacao;  // Timestamp da ultima atualizacao
    }

    // Mapping de endereco para dados do staker
    mapping(address => Staker) public stakers;

    // Total de tokens em stake no contrato
    uint256 public totalStaked;

    // Eventos
    event Staked(address indexed usuario, uint256 quantidade);
    event Unstaked(address indexed usuario, uint256 quantidade);
    event RecompensaResgatada(address indexed usuario, uint256 quantidade);

    /// @notice Constructor: recebe endereco do token e do oraculo
    /// @param _fundToken Endereco do contrato FundToken
    /// @param _priceFeed Endereco do oraculo Chainlink ETH/USD
    constructor(
        address _fundToken,
        address _priceFeed
    ) Ownable(msg.sender) {
        require(_fundToken != address(0), "Endereco do token invalido");
        require(_priceFeed != address(0), "Endereco do oraculo invalido");
        fundToken = IERC20(_fundToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @notice Consulta o preco atual do ETH em USD via Chainlink
    /// @return Preco do ETH em USD (8 casas decimais)
    function obterPrecoETH() public view returns (uint256) {
        (
            ,
            int256 preco,
            ,
            ,
        ) = priceFeed.latestRoundData();
        require(preco > 0, "Preco invalido do oraculo");
        return uint256(preco);
    }

    /// @notice Calcula a recompensa ajustada pelo preco do ETH
    /// @dev Quando ETH esta caro (>2000 USD), recompensa diminui.
    ///      Quando ETH esta barato (<2000 USD), recompensa aumenta.
    /// @param _staker Endereco do staker
    /// @return Recompensa calculada
    function calcularRecompensa(address _staker) public view returns (uint256) {
        Staker memory s = stakers[_staker];
        if (s.saldoStake == 0) return 0;

        uint256 tempoDecorrido = block.timestamp - s.ultimaAtualizacao;
        uint256 precoETH = obterPrecoETH();

        // Preco base de referencia: 2000 USD (com 8 decimais do Chainlink)
        uint256 precoBase = 2000 * 10 ** 8;

        // Ajuste: recompensa = base * (precoBase / precoAtual)
        // Se ETH > 2000 USD, recompensa diminui
        // Se ETH < 2000 USD, recompensa aumenta
        uint256 recompensa = (s.saldoStake * taxaRecompensa * tempoDecorrido * precoBase)
            / (precoETH * 10 ** 18);

        return recompensa;
    }

    /// @notice Atualiza a recompensa acumulada de um staker
    /// @param _staker Endereco do staker
    function _atualizarRecompensa(address _staker) internal {
        stakers[_staker].recompensaAcumulada += calcularRecompensa(_staker);
        stakers[_staker].ultimaAtualizacao = block.timestamp;
    }

    /// @notice Deposita tokens em stake
    /// @param _quantidade Quantidade de tokens a serem travados
    /// @dev O usuario precisa aprovar (approve) o contrato antes de chamar esta funcao
    function stake(uint256 _quantidade) external nonReentrant {
        require(_quantidade > 0, "Quantidade deve ser maior que zero");
        require(
            fundToken.balanceOf(msg.sender) >= _quantidade,
            "Saldo insuficiente"
        );

        // Atualiza recompensa pendente antes de alterar o saldo
        _atualizarRecompensa(msg.sender);

        // Transfere tokens do usuario para o contrato
        fundToken.transferFrom(msg.sender, address(this), _quantidade);

        // Atualiza saldo do staker
        stakers[msg.sender].saldoStake += _quantidade;
        totalStaked += _quantidade;

        emit Staked(msg.sender, _quantidade);
    }

    /// @notice Retira tokens do stake
    /// @param _quantidade Quantidade de tokens a serem retirados
    function unstake(uint256 _quantidade) external nonReentrant {
        require(_quantidade > 0, "Quantidade deve ser maior que zero");
        require(
            stakers[msg.sender].saldoStake >= _quantidade,
            "Saldo em stake insuficiente"
        );

        // Atualiza recompensa pendente antes de alterar o saldo
        _atualizarRecompensa(msg.sender);

        // Atualiza saldo do staker
        stakers[msg.sender].saldoStake -= _quantidade;
        totalStaked -= _quantidade;

        // Devolve tokens ao usuario
        fundToken.transfer(msg.sender, _quantidade);

        emit Unstaked(msg.sender, _quantidade);
    }

    /// @notice Resgata as recompensas acumuladas
    function resgatarRecompensa() external nonReentrant {
        _atualizarRecompensa(msg.sender);

        uint256 recompensa = stakers[msg.sender].recompensaAcumulada;
        require(recompensa > 0, "Sem recompensa disponivel");

        // Zera a recompensa antes de transferir (previne reentrancy)
        stakers[msg.sender].recompensaAcumulada = 0;

        // Transfere recompensa em tokens
        fundToken.transfer(msg.sender, recompensa);

        emit RecompensaResgatada(msg.sender, recompensa);
    }

    /// @notice Permite ao admin alterar a taxa de recompensa
    /// @param _novaTaxa Nova taxa de recompensa
    function setTaxaRecompensa(uint256 _novaTaxa) external onlyOwner {
        require(_novaTaxa > 0, "Taxa deve ser maior que zero");
        taxaRecompensa = _novaTaxa;
    }

    /// @notice Consulta saldo em stake de um usuario
    function saldoEmStake(address _usuario) external view returns (uint256) {
        return stakers[_usuario].saldoStake;
    }

    /// @notice Consulta recompensa pendente de um usuario
    function recompensaPendente(address _usuario) external view returns (uint256) {
        return stakers[_usuario].recompensaAcumulada + calcularRecompensa(_usuario);
    }
}

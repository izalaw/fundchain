// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============================================================================
// FUNDTOKEN — Token ERC-20 da plataforma de crowdfunding
// =============================================================================
//
// Este contrato implementa o token fungivel da plataforma utilizando o padrao
// ERC-20 da OpenZeppelin. O ERC-20 foi escolhido porque todos os tokens sao
// iguais entre si (fungiveis), funcionando como moeda interna da plataforma.
// O token serve para: apoiar projetos, votar na DAO e fazer staking.
//
// A OpenZeppelin e uma biblioteca auditada e amplamente utilizada no mercado,
// o que reduz riscos de seguranca ao evitar reimplementacoes manuais.
// =============================================================================

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title FundToken
/// @notice Token ERC-20 da plataforma de crowdfunding para pequenos negocios de tecnologia

contract FundToken is ERC20, Ownable {

    // Preco do token em wei (0.001 ETH por token)
    uint256 public tokenPrice = 0.001 ether;

    // Eventos
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);

    /// @notice Constructor: define nome, simbolo e faz mint inicial para o deployer
    /// @dev O deployer recebe 1.000.000 de tokens como supply inicial
    constructor() ERC20("FundToken", "FUND") Ownable(msg.sender) {
        // Mint inicial de 1.000.000 tokens para o admin (18 decimais)
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /// @notice Permite que qualquer pessoa compre tokens enviando ETH
    /// @dev O valor em ETH e convertido em tokens com base no tokenPrice
    function buyTokens() external payable {
        require(msg.value > 0, "Envie ETH para comprar tokens");
        
        // Calcula quantos tokens o comprador recebe
        uint256 amount = (msg.value * 10 ** decimals()) / tokenPrice;
        require(amount > 0, "ETH insuficiente para comprar tokens");

        // Transfere tokens do owner para o comprador
        _transfer(owner(), msg.sender, amount);

        emit TokensPurchased(msg.sender, amount, msg.value);
    }

    /// @notice Permite ao admin criar novos tokens (mint)
    /// @param _to Endereco que recebera os tokens
    /// @param _amount Quantidade de tokens a serem criados
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice Permite ao admin alterar o preco do token
    /// @param _newPrice Novo preco em wei
    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Preco deve ser maior que zero");
        tokenPrice = _newPrice;
    }

    /// @notice Permite ao admin retirar o ETH acumulado no contrato
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Sem ETH para retirar");
        payable(owner()).transfer(balance);
    }
}

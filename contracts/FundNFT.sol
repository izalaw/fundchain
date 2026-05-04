// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============================================================================
// FUNDNFT — NFT ERC-721 de certificado de apoiador
// =============================================================================
//
// Este contrato implementa NFTs utilizando o padrao ERC-721 da OpenZeppelin.
// O ERC-721 foi escolhido porque cada certificado de apoiador e unico (nao
// fungivel): contem informacoes especificas como o nome do projeto apoiado
// e a data da contribuicao.
//
// Cada apoiador recebe um NFT como comprovante de participacao na plataforma
// de crowdfunding. Esse NFT serve como selo de "apoiador oficial" e pode
// conferir beneficios futuros.
// =============================================================================

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title FundNFT
/// @notice NFT de certificado para apoiadores da plataforma de crowdfunding

contract FundNFT is ERC721, Ownable {

    // Contador de NFTs emitidos (cada NFT tem um ID unico)
    uint256 private _nextTokenId;

    // Estrutura que armazena os dados de cada NFT
    struct CertificadoApoiador {
        string nomeProjeto;
        address apoiador;
        uint256 valorApoio;
        uint256 dataEmissao;
    }

    // Mapping de tokenId para os dados do certificado
    mapping(uint256 => CertificadoApoiador) public certificados;

    // Mapping para verificar se um endereco ja tem NFT de um projeto
    mapping(address => mapping(string => bool)) public jaApoiou;

    // Eventos
    event CertificadoEmitido(
        uint256 indexed tokenId,
        address indexed apoiador,
        string nomeProjeto,
        uint256 valorApoio
    );

    /// @notice Constructor: define nome e simbolo da colecao de NFTs
    constructor() ERC721("FundNFT", "FNFT") Ownable(msg.sender) {}

    /// @notice Emite um certificado NFT para um apoiador
    /// @param _apoiador Endereco do apoiador
    /// @param _nomeProjeto Nome do projeto apoiado
    /// @param _valorApoio Valor da contribuicao em tokens
    /// @dev Apenas o owner (ou contrato autorizado) pode emitir
    function emitirCertificado(
        address _apoiador,
        string memory _nomeProjeto,
        uint256 _valorApoio
    ) external onlyOwner returns (uint256) {
        // Validacoes de seguranca
        require(_apoiador != address(0), "Endereco invalido");
        require(bytes(_nomeProjeto).length > 0, "Nome do projeto vazio");
        require(!jaApoiou[_apoiador][_nomeProjeto], "Ja possui certificado deste projeto");

        // Gera o ID do novo NFT
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        // Faz o mint do NFT para o apoiador
        _safeMint(_apoiador, tokenId);

        // Armazena os dados do certificado
        certificados[tokenId] = CertificadoApoiador({
            nomeProjeto: _nomeProjeto,
            apoiador: _apoiador,
            valorApoio: _valorApoio,
            dataEmissao: block.timestamp
        });

        // Marca que esse apoiador ja tem certificado deste projeto
        jaApoiou[_apoiador][_nomeProjeto] = true;

        emit CertificadoEmitido(tokenId, _apoiador, _nomeProjeto, _valorApoio);

        return tokenId;
    }

    /// @notice Consulta os dados de um certificado
    /// @param _tokenId ID do NFT
    function consultarCertificado(uint256 _tokenId)
        external
        view
        returns (
            string memory nomeProjeto,
            address apoiador,
            uint256 valorApoio,
            uint256 dataEmissao
        )
    {
        // Verifica se o NFT existe
        require(_ownerOf(_tokenId) != address(0), "NFT nao existe");

        CertificadoApoiador memory cert = certificados[_tokenId];
        return (cert.nomeProjeto, cert.apoiador, cert.valorApoio, cert.dataEmissao);
    }

    /// @notice Retorna o total de NFTs emitidos
    function totalEmitidos() external view returns (uint256) {
        return _nextTokenId;
    }
}

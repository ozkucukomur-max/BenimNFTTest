// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title HerkeseAcikNFT
/// @notice Herkese açık, ücretli mint; 1.000 arz, cüzdan başına en fazla 5 NFT.
contract HerkeseAcikNFT is ERC721, Ownable {
    // ---------- Sabitler ve durum değişkenleri ----------
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_PER_WALLET = 5;

    uint256 public mintPrice; // NFT başına fiyat (wei cinsinden)
    uint256 public totalSupply; // Şimdiye kadar basılan toplam NFT

    mapping(address => uint256) public mintedCount; // Cüzdan başına basılan adet

    string private _baseTokenURI;

    // ---------- Olaylar ----------
    event Minted(address indexed minter, uint256 firstTokenId, uint256 quantity);
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event BaseURIUpdated(string newBaseURI);
    event Withdrawn(address indexed to, uint256 amount);

    // ---------- Hatalar ----------
    error InvalidQuantity();
    error MaxSupplyExceeded();
    error WalletLimitExceeded();
    error IncorrectPayment();
    error NothingToWithdraw();
    error WithdrawFailed();

    // ---------- Kurucu ----------
    constructor(uint256 initialPrice, string memory baseURI_) ERC721("Herkese Acik NFT", "HNFT") Ownable(msg.sender) {
        mintPrice = initialPrice;
        _baseTokenURI = baseURI_;
    }

    // ---------- Herkese açık mint ----------
    function mint(uint256 quantity) external payable {
        if (quantity == 0) revert InvalidQuantity();
        if (totalSupply + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (mintedCount[msg.sender] + quantity > MAX_PER_WALLET) revert WalletLimitExceeded();
        if (msg.value != mintPrice * quantity) revert IncorrectPayment();

        // Önce durumu güncelle, sonra mint et (reentrancy'ye karşı)
        uint256 firstTokenId = totalSupply + 1; // Token ID'ler 1'den başlar
        totalSupply += quantity;
        mintedCount[msg.sender] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, firstTokenId + i);
        }

        emit Minted(msg.sender, firstTokenId, quantity);
    }

    // ---------- Sadece sahip ----------
    function setMintPrice(uint256 newPrice) external onlyOwner {
        emit MintPriceUpdated(mintPrice, newPrice);
        mintPrice = newPrice;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToWithdraw();

        (bool ok,) = payable(owner()).call{value: balance}("");
        if (!ok) revert WithdrawFailed();

        emit Withdrawn(owner(), balance);
    }

    // ---------- İç yardımcı ----------
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}

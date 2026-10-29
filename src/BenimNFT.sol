// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BenimNFT is ERC721, Ownable {
    uint256 public constant MAKS_ARZ = 100;
    uint256 public constant MINT_FIYATI = 0.01 ether;
    uint256 public constant CUZDAN_BASINA_LIMIT = 3;

    uint256 public toplamMint;
    bool public mintAcik;
    string private _temelURI;

    mapping(address => uint256) public mintSayisi;

    error MintKapali();
    error ArzTukendi();
    error YanlisOdeme(uint256 gonderilen, uint256 gereken);
    error CuzdanLimitiAsildi();
    error CekimBasarisiz();

    constructor() ERC721("Benim NFT", "BNFT") Ownable(msg.sender) {}
event NFTMintlendi(
    address indexed alici,
    uint256 indexed tokenId,
    uint256 fiyat
);
    function mint() external payable {
        if (!mintAcik) revert MintKapali();
        if (toplamMint >= MAKS_ARZ) revert ArzTukendi();
        if (msg.value != MINT_FIYATI) revert YanlisOdeme(msg.value, MINT_FIYATI);
        if (mintSayisi[msg.sender] >= CUZDAN_BASINA_LIMIT) revert CuzdanLimitiAsildi();

        // Once durumu guncelle, en son token'i gonder
        mintSayisi[msg.sender] += 1;
        uint256 tokenId = ++toplamMint; // ilk token 1 olur

        _safeMint(msg.sender, tokenId);
 emit NFTMintlendi(msg.sender, tokenId, msg.value);   }

    function mintiAc(bool acik) external onlyOwner {
        mintAcik = acik;
    }

    function temelURIAyarla(string calldata yeniURI) external onlyOwner {
        _temelURI = yeniURI;
    }

    function cekimYap() external onlyOwner {
        (bool basarili, ) = payable(owner()).call{value: address(this).balance}("");
        if (!basarili) revert CekimBasarisiz();
    }

    function _baseURI() internal view override returns (string memory) {
        return _temelURI;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HerkeseAcikNFT} from "../src/HerkeseAcikNFT.sol";

contract YenidenGirisAlicisi {
    HerkeseAcikNFT public nft;
    bool public yenidenGirisReddedildi;

    constructor(HerkeseAcikNFT _nft) {
        nft = _nft;
    }

    function mintBes() external payable {
        nft.mint{value: msg.value}(5);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        (bool basarili,) = address(nft).call{value: nft.mintPrice()}(abi.encodeCall(HerkeseAcikNFT.mint, (1)));

        yenidenGirisReddedildi = !basarili;

        return this.onERC721Received.selector;
    }

    receive() external payable {}
}

contract OdemeKabulEtmeyenSahip {
    function cekimYap(HerkeseAcikNFT nft) external {
        nft.withdraw();
    }

    receive() external payable {
        revert("ETH kabul edilmiyor");
    }
}

contract HerkeseAcikNFTTest is Test {
    HerkeseAcikNFT public nft;

    address public alici = address(0x1234);
    uint256 public sabitFiyat = 0.01 ether;

    function setUp() public {
        nft = new HerkeseAcikNFT(sabitFiyat, "ipfs://test/");

        vm.deal(alici, 10 ether);
    }

    receive() external payable {}

    // 1. Doğru ücretle NFT basılabilmeli.
    function testDogruUcretleMint() public {
        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.mintedCount(alici), 1);
        assertEq(nft.ownerOf(1), alici);
    }

    // 2. Yanlış ödeme reddedilmeli.
    function testYanlisOdemeReddedilir() public {
        vm.expectRevert(HerkeseAcikNFT.IncorrectPayment.selector);
        vm.prank(alici);
        nft.mint{value: sabitFiyat - 1}(1);
    }

    // 3. Sıfır adet NFT basılamamalı.
    function testSifirAdetMintReddedilir() public {
        vm.expectRevert(HerkeseAcikNFT.InvalidQuantity.selector);
        vm.prank(alici);
        nft.mint{value: 0}(0);
    }

    // 4. Bir cüzdan en fazla beş NFT basabilmeli.
    function testCuzdanLimitiBes() public {
        vm.prank(alici);
        nft.mint{value: sabitFiyat * 5}(5);

        assertEq(nft.mintedCount(alici), 5);

        vm.expectRevert(HerkeseAcikNFT.WalletLimitExceeded.selector);
        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);
    }

    // 5. Sahip mint fiyatını değiştirebilmeli.
    function testSahipFiyatDegistirir() public {
        nft.setMintPrice(0.02 ether);

        assertEq(nft.mintPrice(), 0.02 ether);
    }

    // 6. Başka bir kullanıcı mint fiyatını değiştirememeli.
    function testBaskasiFiyatDegistiremez() public {
        vm.expectRevert();
        vm.prank(alici);
        nft.setMintPrice(0.02 ether);
    }

    // 7. Sahip sözleşmedeki ETH'yi çekebilmeli.
    function testSahipParaCekebilir() public {
        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);

        uint256 oncekiBakiye = address(this).balance;

        nft.withdraw();

        assertEq(address(nft).balance, 0);
        assertEq(address(this).balance, oncekiBakiye + sabitFiyat);
    }

    // 8. Başka bir kullanıcı para çekememeli.
    function testBaskasiParaCekemez() public {
        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);

        vm.expectRevert();
        vm.prank(alici);
        nft.withdraw();
    }

    // 9. Toplam arz 1000 NFT sınırını aşamamalı.
    function testToplamArzSiniriAsilamaz() public {
        for (uint256 i = 1; i <= 200; i++) {
            address kullanici = address(uint160(i));

            vm.deal(kullanici, 1 ether);

            vm.prank(kullanici);
            nft.mint{value: sabitFiyat * 5}(5);
        }

        assertEq(nft.totalSupply(), 1000);

        address yeniKullanici = address(0x9999);
        vm.deal(yeniKullanici, 1 ether);

        vm.expectRevert(HerkeseAcikNFT.MaxSupplyExceeded.selector);
        vm.prank(yeniKullanici);
        nft.mint{value: sabitFiyat}(1);
    }

    // 10. Sahip temel URI'yi değiştirebilmeli.
    function testSahipBaseURIyiDegistirir() public {
        nft.setBaseURI("ipfs://yeni-metadata/");

        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);

        assertEq(nft.tokenURI(1), "ipfs://yeni-metadata/1");
    }

    // 11. Başka bir kullanıcı temel URI'yi değiştirememeli.
    function testBaskasiBaseURIyiDegistiremez() public {
        vm.expectRevert();
        vm.prank(alici);
        nft.setBaseURI("ipfs://kotu-metadata/");
    }

    // 12. Toplu mint sırasında yeniden giriş
    // cüzdan limitini aşamamalı.
    function testTopluMintYenidenGirisCuzdanLimitiniAsamaz() public {
        YenidenGirisAlicisi aliciSozlesme = new YenidenGirisAlicisi(nft);

        vm.deal(address(this), 1 ether);
        vm.deal(address(aliciSozlesme), 1 ether);

        aliciSozlesme.mintBes{value: sabitFiyat * 5}();

        assertTrue(aliciSozlesme.yenidenGirisReddedildi());
        assertEq(nft.mintedCount(address(aliciSozlesme)), 5);
        assertEq(nft.totalSupply(), 5);
    }

    // 13. Para alıcısı ödemeyi reddederse
    // çekim başarısız olmalı ve ETH korunmalı.
    function testParaCekmeBasarisizsaBakiyeKorunur() public {
        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);

        OdemeKabulEtmeyenSahip reddedenSahip = new OdemeKabulEtmeyenSahip();

        nft.transferOwnership(address(reddedenSahip));

        vm.expectRevert(HerkeseAcikNFT.WithdrawFailed.selector);
        reddedenSahip.cekimYap(nft);

        assertEq(address(nft).balance, sabitFiyat);
    }
}

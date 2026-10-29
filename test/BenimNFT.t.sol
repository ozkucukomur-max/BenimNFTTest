// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BenimNFT} from "../src/BenimNFT.sol";

contract BenimNFTTest is Test {
    BenimNFT nft;

    function setUp() public {
        nft = new BenimNFT();
    }

    // Test 1: Mint kapaliyken islem basarisiz olmali.
    function testMintKapaliykenBasarisizOlur() public {
        vm.expectRevert(BenimNFT.MintKapali.selector);
        nft.mint{value: 0.01 ether}();
    }

    // Test: Yetkisiz kullanici mint'i acamamali.
    function testBaskasiMintiAcamaz() public {
        address baskasi = address(0x5678);

        vm.prank(baskasi);
        vm.expectRevert();
        nft.mintiAc(true);
    }

    // Test 2: Mint acikken NFT basarili sekilde basilabilmeli.
    function testMintAcikkenNFTBasariliOlur() public {
        nft.mintiAc(true);

        address kullanici = address(0x1234);
        vm.deal(kullanici, 1 ether);

        vm.prank(kullanici);
        nft.mint{value: 0.01 ether}();

        assertEq(nft.toplamMint(), 1);
        assertEq(nft.ownerOf(1), kullanici);
    }

    // Test: Sahip mint'i kapatabilmeli ve mint engellenmeli.
    function testSahipMintiKapatabilir() public {
        nft.mintiAc(true);
        nft.mintiAc(false);

        address kullanici = address(0x4321);
        vm.deal(kullanici, 1 ether);

        vm.expectRevert(BenimNFT.MintKapali.selector);
        vm.prank(kullanici);
        nft.mint{value: 0.01 ether}();

        assertEq(nft.toplamMint(), 0);
    }

    // Test 3: Yanlis odeme reddedilmeli.
    function testYanlisOdemeBasarisizOlur() public {
        nft.mintiAc(true);

        vm.expectRevert(abi.encodeWithSelector(BenimNFT.YanlisOdeme.selector, 0.005 ether, 0.01 ether));

        nft.mint{value: 0.005 ether}();
    }

    // Test 4: Bir cuzdan en fazla 3 NFT basabilmeli.
    function testCuzdanLimitiAsilamaz() public {
        nft.mintiAc(true);

        address kullanici = address(0x1234);
        vm.deal(kullanici, 1 ether);

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(kullanici);
            nft.mint{value: 0.01 ether}();
        }

        vm.expectRevert(BenimNFT.CuzdanLimitiAsildi.selector);
        vm.prank(kullanici);
        nft.mint{value: 0.01 ether}();

        assertEq(nft.mintSayisi(kullanici), 3);
        assertEq(nft.toplamMint(), 3);
    }

    // Test 5: Toplam arz 100 NFT'yi asamaz.
    function testToplamArzAsilamaz() public {
        nft.mintiAc(true);

        for (uint256 i = 0; i < 100; i++) {
            address kullanici = address(uint160(i + 1));
            vm.deal(kullanici, 1 ether);

            vm.prank(kullanici);
            nft.mint{value: 0.01 ether}();
        }

        assertEq(nft.toplamMint(), 100);

        address yeniKullanici = address(0x9999);
        vm.deal(yeniKullanici, 1 ether);

        vm.expectRevert(BenimNFT.ArzTukendi.selector);
        vm.prank(yeniKullanici);
        nft.mint{value: 0.01 ether}();

        assertEq(nft.toplamMint(), 100);
    }

    // Test 6: Sozlesme sahibi biriken parayi cekebilmeli.
    function testSahipParaCekebilir() public {
        nft.mintiAc(true);

        address alici = address(0x1234);
        vm.deal(alici, 1 ether);

        vm.prank(alici);
        nft.mint{value: 0.01 ether}();

        uint256 sahipBakiyesiOnce = address(this).balance;

        nft.cekimYap();

        assertEq(address(nft).balance, 0);
        assertEq(address(this).balance, sahipBakiyesiOnce + 0.01 ether);
    }

    // Test 7: Baska bir kullanici para cekememeli.
    function testBaskasiParaCekemez() public {
        address baskasi = address(0x5678);

        vm.prank(baskasi);
        vm.expectRevert();
        nft.cekimYap();
    }

    // Test 8: Bos bakiyede cekim basarili olmali.
    function testBosBakiyedeCekimBasariliOlur() public {
        nft.cekimYap();

        assertEq(address(nft).balance, 0);
    }

    // Test 9: Yeniden giris saldirisi cuzdan limitini asamamali.
    function testYenidenGirisSaldirisiCuzdanLimitiniAsamaz() public {
        nft.mintiAc(true);

        YenidenGirisSaldirgani saldirgan = new YenidenGirisSaldirgani(nft);
        vm.deal(address(saldirgan), 1 ether);

        saldirgan.saldir();

        assertEq(nft.mintSayisi(address(saldirgan)), 3);
        assertEq(nft.toplamMint(), 3);
        assertEq(saldirgan.basariliMint(), 2);
    }

    // Test sozlesmesi ETH kabul edebilsin.
    receive() external payable {}
}

// Yeniden giris saldirisini deneyen test sozlesmesi.
contract YenidenGirisSaldirgani {
    BenimNFT public immutable nft;
    uint256 public basariliMint;

    constructor(BenimNFT _nft) {
        nft = _nft;
    }

    function saldir() external {
        nft.mint{value: 0.01 ether}();
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        try nft.mint{value: 0.01 ether}() {
            basariliMint += 1;
        } catch {}

        return 0x150b7a02;
    }

    receive() external payable {}
}

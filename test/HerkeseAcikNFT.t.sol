// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HerkeseAcikNFT} from "../src/HerkeseAcikNFT.sol";

contract HerkeseAcikNFTTest is Test {
    receive() external payable {}

    HerkeseAcikNFT nft;

    address alici = address(0x1234);
    uint256 sabitFiyat = 0.01 ether;

    function setUp() public {
        nft = new HerkeseAcikNFT(sabitFiyat, "ipfs://test/");
        vm.deal(alici, 10 ether);
    }

    function testDogruUcretleMint() public {
        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);

        assertEq(nft.ownerOf(1), alici);
        assertEq(nft.totalSupply(), 1);
    }

    function testYanlisOdemeReddedilir() public {
        vm.prank(alici);
        vm.expectRevert(HerkeseAcikNFT.IncorrectPayment.selector);
        nft.mint{value: sabitFiyat - 1}(1);
    }

    function testSifirAdetMintReddedilir() public {
        vm.expectRevert(HerkeseAcikNFT.InvalidQuantity.selector);
        vm.prank(alici);
        nft.mint{value: 0}(0);
    }

    function testCuzdanLimitiBes() public {
        vm.startPrank(alici);
        nft.mint{value: sabitFiyat * 5}(5);

        vm.expectRevert(HerkeseAcikNFT.WalletLimitExceeded.selector);
        nft.mint{value: sabitFiyat}(1);
        vm.stopPrank();
    }

    function testSahipFiyatDegistirir() public {
        nft.setMintPrice(0.02 ether);
        assertEq(nft.mintPrice(), 0.02 ether);
    }

    function testBaskasiFiyatDegistiremez() public {
        vm.prank(alici);
        vm.expectRevert();
        nft.setMintPrice(0.02 ether);
    }

    function testSahipParaCekebilir() public {
        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);

        uint256 oncekiBakiye = address(this).balance;
        nft.withdraw();

        assertEq(address(nft).balance, 0);
        assertEq(address(this).balance, oncekiBakiye + sabitFiyat);
    }

    function testBaskasiParaCekemez() public {
        vm.prank(alici);
        nft.mint{value: sabitFiyat}(1);

        vm.prank(alici);
        vm.expectRevert();
        nft.withdraw();
    }

    function testToplamArzSiniriAsilamaz() public {
        for (uint256 i = 1; i <= 200; i++) {
            address yeniAlici = address(uint160(0x10000 + i));

            vm.deal(yeniAlici, 1 ether);
            vm.prank(yeniAlici);

            nft.mint{value: sabitFiyat * 5}(5);
        }

        assertEq(nft.totalSupply(), nft.MAX_SUPPLY());

        address sonAlici = address(0x999999);
        vm.deal(sonAlici, 1 ether);

        vm.expectRevert(HerkeseAcikNFT.MaxSupplyExceeded.selector);
        vm.prank(sonAlici);
        nft.mint{value: sabitFiyat}(1);
    }
}
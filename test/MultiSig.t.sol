// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSigWallet public multiSig;

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = makeAddr("owner1");
        owners[1] = makeAddr("owner2");
        owners[2] = makeAddr("owner3");
        multiSig = new MultiSigWallet(owners, 2);
    }

    function test_Increment() public {
        multiSig.submit(address(0), 0, bytes(""));
        assertEq(multiSig.transactions(0), address(0));
    }

    function testFuzz_SetNumber(uint256 x) public {
        multiSig.submit(address(0), 0, bytes(""));
        assertEq(multiSig.transactions(0), address(0));
    }
}

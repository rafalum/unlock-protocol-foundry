// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";

import { ERC1967Proxy } from "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IUnlock } from "../lib/unlock/smart-contracts/contracts/interfaces/IUnlock.sol";
import { IPublicLock } from "../lib/unlock/smart-contracts/contracts/interfaces/IPublicLock.sol";

import { Unlock } from "../lib/unlock/smart-contracts/contracts/Unlock.sol";
import { PublicLock } from "../lib/unlock/smart-contracts/contracts/PublicLock.sol";

import { LockFactory } from "../src/LockFactory.sol";

contract LockFactoryTest is Test {
    IPublicLock lock;

    event DebugEvent(string message, address addr);

    function setUp() public {
        // create the unlock contract which serves as a factory for locks
        address unlock = address(new Unlock());
        emit DebugEvent("Unlock address", unlock);

        address deployer = address(this);
        emit DebugEvent("Deployer address", deployer);

        // create proxy for unlock contract
        bytes memory data = abi.encodeCall(Unlock.initialize, deployer);
        address proxy = address(new ERC1967Proxy(unlock, data));
        emit DebugEvent("Proxy address", proxy);

        // create a new public lock template
        address impl = address(new PublicLock());

        IUnlock(proxy).addLockTemplate(impl, 1);
        IUnlock(proxy).setLockTemplate(payable(impl));

        LockFactory factory = new LockFactory(IUnlock(proxy));

        lock = IPublicLock(factory.lockAddress());
    }

    function testPurchaseKey() public {
        address randomAddress = address(1337);

        vm.deal(randomAddress, 1 ether);
        vm.prank(randomAddress);

        uint256 balanceBeforPurchase = lock.balanceOf(randomAddress);
        assertEq(balanceBeforPurchase, 0);

        // create a new key
        uint256[] memory _values = new uint256[](1);
        _values[0] = 0.011 ether;

        address[] memory _recipients = new address[](1);
        _recipients[0] = randomAddress;

        address[] memory _referrers = new address[](1);
        _referrers[0] = randomAddress;

        address[] memory _keyManagers = new address[](1);
        _keyManagers[0] = randomAddress;

        bytes[] memory _data = new bytes[](1);
        _data[0] = bytes("0x");

        lock.purchase{ value: 0.011 ether }(_values, _recipients, _referrers, _keyManagers, _data);

        uint256 balanceAfterPurchase = lock.balanceOf(randomAddress);
        assertEq(balanceAfterPurchase, 1);
    }
}

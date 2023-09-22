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
    IPublicLock public lock;
    LockFactory public factory;

    address public deployer = address(42);

    event DebugEvent(string message, address addr);

    function setUp() public {
        // create the unlock contract which serves as a factory for locks
        address unlock = address(new Unlock());
        emit DebugEvent("Unlock address", unlock);

        // create proxy for unlock contract
        bytes memory data = abi.encodeCall(Unlock.initialize, deployer);
        vm.prank(deployer);
        address proxy = address(new ERC1967Proxy(unlock, data));
        emit DebugEvent("Proxy address", proxy);

        // create a new public lock template
        address impl = address(new PublicLock());

        vm.prank(deployer);
        IUnlock(proxy).addLockTemplate(impl, 1);

        vm.prank(deployer);
        IUnlock(proxy).setLockTemplate(payable(impl));

        factory = new LockFactory(IUnlock(proxy));

        lock = IPublicLock(factory.lockAddress());
    }

    function testInit() public {
        bool isLockManager = lock.isLockManager(address(factory));
        assertTrue(isLockManager);

        bool isOwner = lock.isOwner(address(factory));
        assertTrue(isOwner);

        uint256 expirationDuration = lock.expirationDuration();
        assertEq(expirationDuration, 2_592_000);
    }

    function testPurchaseKey() public {
        address randomAddress = address(1337);
        vm.deal(randomAddress, 1 ether);

        uint256 balanceBeforePurchase = lock.balanceOf(randomAddress);
        assertEq(balanceBeforePurchase, 0);

        _purchaseKey(randomAddress);

        uint256 balanceAfterPurchase = lock.balanceOf(randomAddress);
        assertEq(balanceAfterPurchase, 1);
    }

    function testExpiration() public {
        address randomAddress = address(1338);
        vm.deal(randomAddress, 1 ether);

        uint256[] memory ids = _purchaseKey(randomAddress);
        uint256 _tokenId = ids[0];

        uint256 expiration = lock.keyExpirationTimestampFor(_tokenId);

        bool isValid = lock.isValidKey(_tokenId);
        assertTrue(isValid);

        vm.warp(expiration - 1);

        isValid = lock.isValidKey(_tokenId);
        assertTrue(isValid);

        vm.warp(expiration);

        isValid = lock.isValidKey(_tokenId);
        assertFalse(isValid);
    }

    function _purchaseKey(address buyer) public returns (uint256[] memory) {
        vm.prank(buyer);

        // create a new key
        uint256[] memory _values = new uint256[](1);
        _values[0] = 0.01 ether;

        address[] memory _recipients = new address[](1);
        _recipients[0] = buyer;

        address[] memory _referrers = new address[](1);
        _referrers[0] = buyer;

        address[] memory _keyManagers = new address[](1);
        _keyManagers[0] = buyer;

        bytes[] memory _data = new bytes[](1);
        _data[0] = bytes("0x");

        return lock.purchase{ value: 0.01 ether }(_values, _recipients, _referrers, _keyManagers, _data);
    }
}

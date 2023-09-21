// SPDX-License-Identifier: MIT
import { IUnlock } from "../lib/unlock/smart-contracts/contracts/interfaces/IUnlock.sol";
import { IPublicLock } from "../lib/unlock/smart-contracts/contracts/interfaces/IPublicLock.sol";

pragma solidity ^0.8.17;

contract LockFactory {
    address public lockAddress;
    address public unlockAddress;

    constructor(IUnlock _unlock) {
        IUnlock unlock = _unlock;
        unlockAddress = address(unlock);

        uint256 _expirationDuration = 2_592_000; // 30 days
        address _tokenAddress = address(0);
        uint256 _keyPrice = 10_000_000_000_000_000; // 0.01 ETH
        uint256 _maxNumberOfKeys = 1;
        string memory _lockName = "MyLock";
        bytes12 _salt = bytes12(0);

        lockAddress =
            unlock.createLock(_expirationDuration, _tokenAddress, _keyPrice, _maxNumberOfKeys, _lockName, _salt);
    }
}

// SPDX-License-Identifier: MIT 
import {IUnlock} from "../lib/unlock/smart-contracts/contracts/interfaces/IUnlock.sol";
import {IPublicLock} from "../lib/unlock/smart-contracts/contracts/interfaces/IPublicLock.sol";

pragma solidity ^0.8.0;

contract LockFactory {

  address public lockAddress;
  address public unlockAddress;

  constructor(IUnlock _unlock) {

    IUnlock unlock = _unlock;
    unlockAddress = address(unlock);

    uint _expirationDuration = 2592000; // 30 days
    address _tokenAddress = address(0);
    uint _keyPrice = 10000000000000000; // 0.01 ETH
    uint _maxNumberOfKeys = 1;
    string memory _lockName = "MyLock";
    bytes12 _salt = bytes12(0);

    lockAddress = unlock.createLock(_expirationDuration, _tokenAddress, _keyPrice, _maxNumberOfKeys, _lockName, _salt);

  }
}
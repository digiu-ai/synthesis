// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//WARN: Before release should be baned trustListForDex into addNode
contract NodeListMock {

    function checkPermissionTrustList(address node) external view returns (bool)  {
        return true;
    }
}

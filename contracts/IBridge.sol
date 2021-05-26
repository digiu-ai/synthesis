pragma solidity ^0.8.0;

interface IBridge {
     function transmitRequestV2(bytes memory owner, address spender) external  returns (bytes32);
}

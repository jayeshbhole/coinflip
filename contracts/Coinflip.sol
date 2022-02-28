pragma solidity == 0.8.0


contract CoinFlip {
    // struct {
    //      id
    //      user_address
    //      outcome
    // }

    // Mapping of users balances

    // Array of Ongoing bets

    // Array of Completed bets
    // { account: [...] }


    // Harmony VRF
    function vrf() public view returns (bytes32 result) {
        uint[1] memory bn;
        bn[0] = block.number;
        assembly {
        let memPtr := mload(0x40)
        if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
            invalid()
        }
        result := mload(memPtr)
        }
    }
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity <=0.8.7;

contract CoinFlip {
    struct Bet {
        uint256 id;
        address player;
        uint256 amount;
        uint256 bet;
    }

    // Mapping of users balances
    mapping(address => uint256) balances;
    // Array of Ongoing bets
    Bet[] ongoingBets;
    // Array of Completed bets
    Bet[] completedBets;

    // Mapping of isOngoingBet flag. user => isOngoingBet
    mapping(address => bool) isOngoingBets;

    // Bet placed event
    event BetPlaced(uint256 id, address player, uint256 amount, uint256 bet);
    // Bet result event
    event BetResult(
        uint256 id,
        address player,
        uint256 payout,
        uint256 bet,
        uint256 outcome
    );

    // Harmony => verifiable random function
    function vrf() public view returns (bytes32 result) {
        uint256[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
    }

    // Place bet function. accepts amount = integer and bet = 0 or 1 representing heads or tails
    function placeBet(uint256 _amount, uint256 _bet)
        public
        payable
        returns (uint256 betId)
    {
        // Check if bet is 0 or 1
        require(_bet == 0 || _bet == 1, "Bet must be 0 or 1");

        // Check if bet is valid
        require(_amount > 0, "Bet must be greater than 0");

        // Check if user has enough balance
        require(
            balances[msg.sender] >= _amount,
            "You don't have enough balance"
        );

        // Check if user has already placed a bet
        require(!isOngoingBets[msg.sender], "You have already placed a bet");

        // Create a new Bet and
        // Add new bet to ongoing bets
        ongoingBets.push(Bet(completedBets.length, msg.sender, _amount, _bet));

        // Set isOngoingBet flag to true
        isOngoingBets[msg.sender] = true;

        // Subtract bet amount from user balance
        balances[msg.sender] -= _amount;

        // Emit event
        emit BetPlaced(completedBets.length, msg.sender, _amount, _bet);

        // return id of bet
        return completedBets.length;
    }

    // calculate rewards for ongoing bets function
    function rewardBets() public {
        // Use VRF to determine game outcome
        uint8 outcome = uint8(uint256(vrf())) % 2;

        // Iterate through ongoing bets
        for (uint256 i = 0; i < ongoingBets.length; i++) {
            // If bet and outcome match
            if (ongoingBets[i].bet == outcome) {
                // Add bet amount to user balance
                balances[ongoingBets[i].player] += 2 * ongoingBets[i].amount;
            }

            // Add bet to completed bets
            completedBets.push(ongoingBets[i]);

            // emit bet result event
            emit BetResult(
                ongoingBets[i].id,
                ongoingBets[i].player,
                2 * ongoingBets[i].amount,
                ongoingBets[i].bet,
                outcome
            );

            // Add bet to completed bets
            completedBets.push(ongoingBets[i]);
        }
    }
}

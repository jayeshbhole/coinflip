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
    mapping(address => uint256) private balances;
    mapping(address => bool) private existingUser;

    // Array of Ongoing bets
    Bet[] public ongoingBets;
    // Array of Completed bets
    Bet[] public completedBets;

    // Mapping of isUserBetting flag. user => isUserBetting
    mapping(address => bool) isUserBetting;

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

    function balanceOf(address _user) public view returns (uint256) {
        if (existingUser[_user] == false) return 100;
        return balances[_user];
    }

    // Place bet function. accepts amount = integer and bet = 0 or 1 representing heads or tails
    function placeBet(uint256 _amount, uint256 _bet)
        public
        payable
        returns (uint256 betId)
    {
        require(_bet == 0 || _bet == 1, "Bet must be 0 or 1");
        require(_amount > 0, "Bet must be greater than 0");

        if (existingUser[msg.sender] == false) {
            existingUser[msg.sender] = true;
            balances[msg.sender] = 100;
        }
        require(balances[msg.sender] >= _amount, "Not enough balance");

        // Check if user has already placed a bet
        require(!isUserBetting[msg.sender], "You have already placed a bet");

        // Create a new Bet and
        // Add new bet to ongoing bets
        ongoingBets.push(Bet(completedBets.length, msg.sender, _amount, _bet));

        // Set isUserBetting flag to true
        isUserBetting[msg.sender] = true;

        // Subtract bet amount from user balance
        balances[msg.sender] -= _amount;

        // Emit event
        emit BetPlaced(completedBets.length, msg.sender, _amount, _bet);

        // return id of bet
        return completedBets.length;
    }

    // calculate rewards for ongoing bets function
    function rewardBets() public {
        require(ongoingBets.length > 0, "No ongoing bets");

        // Use VRF to determine game outcome
        uint8 outcome = uint8(uint256(vrf())) % 2;

        // Iterate through ongoing bets
        for (uint256 i = 0; i < ongoingBets.length; i++) {
            Bet memory currentBet = ongoingBets[i];

            // If bet and outcome match
            if (currentBet.bet == outcome) {
                // Add bet amount to user balance
                balances[currentBet.player] += 2 * currentBet.amount;
            }

            // set isUserBetting flag to false for player
            isUserBetting[currentBet.player] = false;

            // Add bet to completed bets
            completedBets.push(currentBet);

            // emit bet result event
            emit BetResult(
                currentBet.id,
                currentBet.player,
                2 * currentBet.amount,
                currentBet.bet,
                outcome
            );

            // Add bet to completed bets
            completedBets.push(currentBet);
        }

        // Clear ongoing bets array
        delete ongoingBets;
    }
}

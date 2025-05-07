pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@fhenixprotocol/contracts/access/Permissioned.sol";
import "@fhenixprotocol/contracts/FHE.sol";

contract ColdbrewToken is ERC20, Permissioned {
    mapping(address => euint32) internal _encBalances;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
    }

    function wrap(uint32 amount) public {
        // Make sure that the sender has enough of the public balance
        require(balanceOf(msg.sender) >= amount);
        // Burn public balance
        _burn(msg.sender, amount);

        // convert public amount to shielded by encrypting it
        euint32 shieldedAmount = FHE.asEuint32(amount);
        // Add shielded balance to his current balance
        _encBalances[msg.sender] = _encBalances[msg.sender] + shieldedAmount;
    }

    function unwrap(inEuint32 memory amount) public {
        // verify that the input is a valid encrypted number
        euint32 _amount = FHE.asEuint32(amount);
        // verify that our shielded balance is greater or equal than the requested amount. (gte = greater-than-or-equal)
        FHE.req(_encBalances[msg.sender].gte(_amount));
        // subtract amount from shielded balance
        _encBalances[msg.sender] = _encBalances[msg.sender] - _amount;
        // add amount to caller's public balance by calling the `mint` function
        _mint(msg.sender, FHE.decrypt(_amount));
    }

    function transferEncrypted(address to, inEuint32 calldata encryptedAmount) public {
        euint32 amount = FHE.asEuint32(encryptedAmount);
        // Make sure the sender has enough tokens. (lte = less-then-or-equal)
        FHE.req(amount.lte(_encBalances[msg.sender]));

        // Add to the balance of `to` and subract from the balance of `msg.sender`.
        _encBalances[to] = _encBalances[to] + amount;
        _encBalances[msg.sender] = _encBalances[msg.sender] - amount;
    }

    function getBalanceEncrypted(Permission calldata perm) public view onlySender(perm) returns (uint256) {
        return FHE.decrypt(_encBalances[msg.sender]);
    }
}

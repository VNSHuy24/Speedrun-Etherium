// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    // --- Biến trạng thái (State Variables) ---
    ExampleExternalContract public exampleExternalContract;
    
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    
    // Thêm biến deadline (theo Checkpoint 2)
    uint256 public deadline = block.timestamp + 72 hours; 
    
    // Sự kiện
    event Stake(address indexed sender, uint256 amount);
    
    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    // Add the `receive()` special function that receives eth and calls stake()
    // --- Các hàm (Functions) ---

    function stake() public payable {
        // Cập nhật số dư
        balances[msg.sender] += msg.value;
        // Phát sự kiện
        emit Stake(msg.sender, msg.value);
    }

    // Bạn sẽ viết tiếp các hàm execute, withdraw, timeLeft ở đây..
    function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
        return 0;
    } else {
        return deadline - block.timestamp;
    }
    }
    
    // Trạng thái cho phép rút tiền (mặc định là false)
bool public openForWithdraw;

// Modifier để đảm bảo dự án chưa hoàn thành trên External Contract
modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Project already completed");
    _;
}

// Hàm execute: Quyết định chuyển tiền đi hay cho rút lại
function execute() public notCompleted {
    require(block.timestamp >= deadline, "Deadline not reached yet");

    if (address(this).balance >= threshold) {
        // Đạt mục tiêu: Chuyển toàn bộ tiền sang External Contract
        exampleExternalContract.complete{value: address(this).balance}();
    } else {
        // Thất bại: Mở cổng rút tiền
        openForWithdraw = true;
    }
}

// Hàm withdraw: Người dùng rút tiền nếu mục tiêu thất bại
function withdraw() public notCompleted {
    require(openForWithdraw, "Withdrawals are not open");
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "No balance to withdraw");

    balances[msg.sender] = 0; // Chống tấn công Reentrancy
    (bool sent, ) = msg.sender.call{value: userBalance}("");
    require(sent, "Failed to send Ether");
}

// Hàm receive: Nhận ETH trực tiếp và tự động gọi stake()
receive() external payable {
    stake();
}
}
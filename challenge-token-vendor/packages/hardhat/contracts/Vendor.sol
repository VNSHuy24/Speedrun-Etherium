// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";


contract Vendor is Ownable {
    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);


    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    // Hàm mua Token
    function buyTokens() public payable {
        uint256 amountToBuy = msg.value * tokensPerEth;
        
        // Kiểm tra xem Vendor có đủ token để bán không
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Vendor has insufficient tokens");

        // Chuyển token cho người mua
        bool sent = yourToken.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer tokens");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    // Hàm rút ETH (Chỉ chủ sở hữu contract mới được rút)
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "No ETH to withdraw");
        
        (bool sent, ) = msg.sender.call{value: ownerBalance}("");
        require(sent, "Failed to send ETH");
    }
    
    function sellTokens(uint256 amount) public {
    require(amount > 0, "Amount must be greater than 0");

    // Tính số ETH phải trả (1 ETH = 100 tokens => ETH = tokens / 100)
    uint256 amountOfETH = amount / tokensPerEth;
    require(address(this).balance >= amountOfETH, "Vendor has insufficient ETH");

    // Lấy token từ người dùng (Người dùng phải Approve trước đó)
    bool sent = yourToken.transferFrom(msg.sender, address(this), amount);
    require(sent, "Failed to transfer tokens from user");

    // Trả ETH cho người dùng
    (bool ethSent, ) = msg.sender.call{value: amountOfETH}("");
    require(ethSent, "Failed to send ETH to user");

    emit SellTokens(msg.sender, amount, amountOfETH);
}
}
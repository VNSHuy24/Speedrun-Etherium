// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX
 * @notice Sàn giao dịch phi tập trung tối giản sử dụng công thức x * y = k
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    IERC20 public token; // Balloon Token ($BAL)
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    /* ========== EVENTS ========== */

    event EthToTokenSwap(address swapper, uint256 tokenOutput, uint256 ethInput);
    event TokenToEthSwap(address swapper, uint256 tokensInput, uint256 ethOutput);
    event LiquidityProvided(address liquidityProvider, uint256 liquidityMinted, uint256 ethInput, uint256 tokensInput);
    event LiquidityRemoved(address liquidityRemover, uint256 liquidityWithdrawn, uint256 tokensOutput, uint256 ethOutput);

    /* ========== CONSTRUCTOR ========== */

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Khởi tạo thanh khoản ban đầu. Chỉ được gọi 1 lần khi totalLiquidity = 0.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: init - already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: init - transfer failed");
        return totalLiquidity;
    }

    /**
     * @notice Công thức tính giá: (xInput * 997 * yReserves) / (xReserves * 1000 + xInput * 997)
     * Đã bao gồm 0.3% phí giao dịch.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = (xReserves * 1000) + xInputWithFee;
        return (numerator / denominator);
    }

    /**
     * @notice Trả về lượng thanh khoản của một user (Dùng cho test case và Frontend)
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice Đổi ETH lấy Token $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "cannot swap 0 ETH");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        tokenOutput = price(msg.value, ethReserve, tokenReserve);

        require(token.transfer(msg.sender, tokenOutput), "ethToToken(): reverted swap.");
        emit EthToTokenSwap(msg.sender, tokenOutput, msg.value);
        return tokenOutput;
    }

    /**
     * @notice Đổi Token $BAL lấy ETH
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");
        uint256 tokenReserve = token.balanceOf(address(this));
        ethOutput = price(tokenInput, tokenReserve, address(this).balance);
        
        require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth(): reverted swap.");
        (bool sent, ) = msg.sender.call{value: ethOutput}("");
        require(sent, "tokenToEth: revert in transferring eth");
        
        emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
        return ethOutput;
    }

    /**
     * @notice Nạp thêm thanh khoản theo tỉ lệ hiện tại của pool
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "Must send ETH");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        
        // Tính toán lượng token cần nạp tương ứng để giữ nguyên tỉ lệ x/y
        uint256 tokenDeposit = (msg.value * tokenReserve / ethReserve) + 1;
        uint256 liquidityMinted = msg.value * totalLiquidity / ethReserve;

        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        require(token.transferFrom(msg.sender, address(this), tokenDeposit), "deposit: transfer failed");
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenDeposit);
        return tokenDeposit;
    }

    /**
     * @notice Rút thanh khoản (Nhận lại cả ETH và BAL)
     */
    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(liquidity[msg.sender] >= amount, "withdraw: insufficient liquidity");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));

        uint256 ethWithdrawn = (amount * ethReserve) / totalLiquidity;
        uint256 tokenWithdrawn = (amount * tokenReserve) / totalLiquidity;

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        (bool sent, ) = payable(msg.sender).call{value: ethWithdrawn}("");
        require(sent, "withdraw: eth transfer failed");
        require(token.transfer(msg.sender, tokenWithdrawn), "withdraw: token transfer failed");

        emit LiquidityRemoved(msg.sender, amount, tokenWithdrawn, ethWithdrawn);
        return (ethWithdrawn, tokenWithdrawn);
    }
}
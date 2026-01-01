// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Corn.sol";
import "./CornDEX.sol";

error Lending__InvalidAmount();
error Lending__TransferFailed();
error Lending__UnsafePositionRatio();
error Lending__BorrowingFailed();
error Lending__RepayingFailed();
error Lending__PositionSafe();
error Lending__NotLiquidatable();
error Lending__InsufficientLiquidatorCorn();

contract Lending is Ownable {
    uint256 private constant COLLATERAL_RATIO = 120; // 120% tỷ lệ thế chấp tối thiểu
    uint256 private constant LIQUIDATOR_REWARD = 10; // 10% thưởng cho người thanh lý

    Corn private i_corn;
    CornDEX private i_cornDEX;

    mapping(address => uint256) public s_userCollateral; // Số dư ETH thế chấp của user
    mapping(address => uint256) public s_userBorrowed; // Số nợ CORN của user

    event CollateralAdded(address indexed user, uint256 indexed amount, uint256 price);
    event CollateralWithdrawn(address indexed user, uint256 indexed amount, uint256 price);
    event AssetBorrowed(address indexed user, uint256 indexed amount, uint256 price);
    event AssetRepaid(address indexed user, uint256 indexed amount, uint256 price);
    event Liquidation(
        address indexed user,
        address indexed liquidator,
        uint256 amountForLiquidator,
        uint256 liquidatedUserDebt,
        uint256 price
    );

    constructor(address _cornDEX, address _corn) Ownable(msg.sender) {
        i_cornDEX = CornDEX(_cornDEX);
        i_corn = Corn(_corn);
        // Cho phép contract tự lấy token CORN từ chính nó để chuyển cho user khi họ vay
        i_corn.approve(address(this), type(uint256).max);
    }

    /**
     * @notice Bước 1: Nạp ETH làm tài sản thế chấp
     */
    function addCollateral() public payable {
        if (msg.value == 0) revert Lending__InvalidAmount();
        s_userCollateral[msg.sender] += msg.value;
        emit CollateralAdded(msg.sender, msg.value, i_cornDEX.currentPrice());
    }

    /**
     * @notice Bước 2: Rút ETH (Chỉ khi vị thế vẫn an toàn)
     */
    function withdrawCollateral(uint256 amount) public {
        if (amount == 0 || s_userCollateral[msg.sender] < amount) revert Lending__InvalidAmount();
        
        s_userCollateral[msg.sender] -= amount;

        // Kiểm tra xem sau khi rút có bị thanh lý không (Checkpoint 6)
        if (s_userBorrowed[msg.sender] > 0) {
            _validatePosition(msg.sender);
        }

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert Lending__TransferFailed();

        emit CollateralWithdrawn(msg.sender, amount, i_cornDEX.currentPrice());
    }

    /**
     * @notice Tính giá trị tài sản thế chấp theo đơn vị CORN
     */
    function calculateCollateralValue(address user) public view returns (uint256) {
        uint256 collateralAmount = s_userCollateral[user];
        return (collateralAmount * i_cornDEX.currentPrice()) / 1e18;
    }

    /**
     * @notice Tính tỷ lệ an toàn (Position Ratio)
     */
    function _calculatePositionRatio(address user) internal view returns (uint256) {
        uint256 borrowedAmount = s_userBorrowed[user];
        if (borrowedAmount == 0) return type(uint256).max;
        
        uint256 collateralValue = calculateCollateralValue(user);
        return (collateralValue * 1e18) / borrowedAmount;
    }

    /**
     * @notice Kiểm tra xem user có bị thanh lý không (< 120%)
     */
    function isLiquidatable(address user) public view returns (bool) {
        uint256 positionRatio = _calculatePositionRatio(user);
        return (positionRatio * 100) < COLLATERAL_RATIO * 1e18;
    }

    function _validatePosition(address user) internal view {
        if (isLiquidatable(user)) revert Lending__UnsafePositionRatio();
    }

    /**
     * @notice Vay CORN dựa trên tài sản thế chấp
     */
    function borrowCorn(uint256 borrowAmount) public {
        if (borrowAmount == 0) revert Lending__InvalidAmount();
        
        s_userBorrowed[msg.sender] += borrowAmount;
        _validatePosition(msg.sender); // Phải đủ 120% mới cho vay

        bool success = i_corn.transfer(msg.sender, borrowAmount);
        if (!success) revert Lending__BorrowingFailed();

        emit AssetBorrowed(msg.sender, borrowAmount, i_cornDEX.currentPrice());
    }

    /**
     * @notice Trả nợ CORN
     */
    function repayCorn(uint256 repayAmount) public {
        if (repayAmount == 0 || repayAmount > s_userBorrowed[msg.sender]) revert Lending__InvalidAmount();
        
        s_userBorrowed[msg.sender] -= repayAmount;
        // User phải approve cho contract lấy CORN từ ví của họ trước
        bool success = i_corn.transferFrom(msg.sender, address(this), repayAmount);
        if (!success) revert Lending__RepayingFailed();

        emit AssetRepaid(msg.sender, repayAmount, i_cornDEX.currentPrice());
    }

    /**
     * @notice Thanh lý tài sản nợ xấu
     */
    function liquidate(address user) public {
        if (!isLiquidatable(user)) revert Lending__NotLiquidatable();

        uint256 userDebt = s_userBorrowed[user];
        if (i_corn.balanceOf(msg.sender) < userDebt) revert Lending__InsufficientLiquidatorCorn();

        // 1. Người thanh lý trả nợ hộ
        i_corn.transferFrom(msg.sender, address(this), userDebt);
        s_userBorrowed[user] = 0;

        // 2. Tính thưởng 110% giá trị nợ trả bằng ETH thế chấp
        uint256 collateralValueInCorn = calculateCollateralValue(user);
        uint256 collateralToLiquidator = (s_userCollateral[user] * userDebt) / collateralValueInCorn;
        uint256 bonus = (collateralToLiquidator * LIQUIDATOR_REWARD) / 100;
        uint256 totalReward = collateralToLiquidator + bonus;

        // Đảm bảo không rút quá số ETH user có
        if (totalReward > s_userCollateral[user]) totalReward = s_userCollateral[user];

        s_userCollateral[user] -= totalReward;

        (bool success, ) = payable(msg.sender).call{value: totalReward}("");
        if (!success) revert Lending__TransferFailed();

        emit Liquidation(user, msg.sender, totalReward, userDebt, i_cornDEX.currentPrice());
    }
}
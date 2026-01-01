import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { DEX } from "../typechain-types/contracts/DEX";
import { Balloons } from "../typechain-types/contracts/Balloons";

const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // 1. Deploy Balloons Token
  await deploy("Balloons", {
    from: deployer,
    log: true,
    autoMine: true,
  });

  const balloons: Balloons = await hre.ethers.getContract("Balloons", deployer);
  const balloonsAddress = await balloons.getAddress();

  // 2. Deploy DEX với địa chỉ Balloons
  await deploy("DEX", {
    from: deployer,
    args: [balloonsAddress],
    log: true,
    autoMine: true,
  });

  const dex = (await hre.ethers.getContract("DEX", deployer)) as DEX;
  const dexAddress = await dex.getAddress();

  // 3. Tặng 100 Balloons cho ví Frontend của bạn để bạn có thể test Swap/Deposit
  // THAY "0x..." BẰNG ĐỊA CHỈ VÍ METAMASK CỦA BẠN
  console.log("Sending balloons to frontend address...");
  await balloons.transfer("0xdcAf63dAE8C73e64A49FcF35f4718635664b1FF4", hre.ethers.parseEther("100"));

  // 4. KHỞI TẠO THANH KHOẢN (INIT)
  // Bước này cực kỳ quan trọng để thiết lập tỉ lệ giá 1:1 ban đầu
  console.log("Approving DEX to take Balloons...");
  
  // Cho phép DEX chi tiêu 100 token của deployer
  await balloons.approve(dexAddress, hre.ethers.parseEther("100"));
  
  console.log("INIT exchange with 5 ETH and 5 Balloons...");
  // Nạp 5 ETH và 5 Balloons vào pool
  await dex.init(hre.ethers.parseEther("1"), {
    value: hre.ethers.parseEther("1"),
    gasLimit: 200000,
  });
};

export default deployYourContract;
deployYourContract.tags = ["Balloons", "DEX"];
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers"; // Mở khóa import này

/**
 * Deploys a contract named "Vendor" using the deployer account
 */
const deployVendor: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // 1. Lấy instance của YourToken đã deploy trước đó để lấy địa chỉ
  const yourToken = await hre.ethers.getContract<Contract>("YourToken", deployer);
  const yourTokenAddress = await yourToken.getAddress();

  // 2. Deploy Vendor với tham số constructor là địa chỉ YourToken
  await deploy("Vendor", {
    from: deployer,
    args: [yourTokenAddress],
    log: true,
    autoMine: true,
  });

  // 3. Lấy instance của Vendor vừa deploy xong
  const vendor = await hre.ethers.getContract<Contract>("Vendor", deployer);
  const vendorAddress = await vendor.getAddress();

  // 4. Chuyển 1000 Token từ ví deployer sang ví của Vendor để nó có hàng để bán
  console.log("\n 🏵 Sending 1000 tokens to Vendor...");
  await yourToken.transfer(vendorAddress, hre.ethers.parseEther("1000"));

  // 5. Chuyển quyền sở hữu (Ownership) cho ví Frontend của bạn
  // QUAN TRỌNG: Thay địa chỉ bên dưới bằng địa chỉ ví bạn thấy ở góc trên bên phải localhost:3000
  console.log("\n 👨‍💼 Transferring ownership to your frontend address...");
  await vendor.transferOwnership("0xA125fdcaa5aD91F7cFD0826306d49187502B7B31"); 
};

export default deployVendor;

deployVendor.tags = ["Vendor"];
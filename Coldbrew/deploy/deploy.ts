import { DeployFunction } from "hardhat-deploy/types";
const hre = require("hardhat");

const func: DeployFunction = async function () {
  const { ethers } = hre;
  const { deploy } = hre.deployments;
  const [signer] = await ethers.getSigners();

  const counter = await deploy("WrappingERC20", {
    from: signer.address,
    args: ["Test Token", "TST"],
    log: true,
    skipIfAlreadyDeployed: false,
  });

  console.log(`Counter contract: `, counter.address);
};

export default func;
func.id = "deploy_counter";
func.tags = ["WrappingERC20"];

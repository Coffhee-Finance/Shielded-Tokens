import {WrappingERC20} from "../types/contracts/WrappingERC20";
import hre, { ethers } from 'hardhat';
import { Permit } from "fhenixjs";

describe('Test WERC20', () =>  {
  let contractAddr: string;
  let contract: WrappingERC20;
  let permit: Permit;
  let owner: string;
  let destination: string = "0x1245dD4AdB920c460773a105e1B3345707B4834A";

  const amountToSend = BigInt(1);

  // We don't really need it as test but it is a test since it is async
  it(`Test Contract Deployment`, async () => {
    const { ethers, fhenixjs } = hre;
    const { deploy } = hre.deployments;
    const [signer] = await ethers.getSigners();

    owner = signer.address;

    const token = await deploy("WrappingERC20", {
      from: signer.address,
      args: ["Test Token", "TST"],
      log: true,
      skipIfAlreadyDeployed: false,
    });

    contractAddr = token.address;

    permit = await fhenixjs.generatePermit(contractAddr, undefined, signer);
    contract = (await ethers.getContractAt("WrappingERC20", contractAddr)) as unknown as WrappingERC20;

    console.log(`contractAddr: `, contractAddr);
  });

  it(`Wrap Tokens`, async () => {

    let balanceBefore = await contract.balanceOf(owner);
    let privateBalanceBefore = await contract.getBalanceEncrypted(permit);
    console.log(`Public Balance before wrapping: ${balanceBefore}`);
    console.log(`Private Balance before wrapping: ${privateBalanceBefore}`);

    await contract.wrap(amountToSend);

    let balanceAfter = await contract.balanceOf(owner);
    let privateBalanceAfter = await contract.getBalanceEncrypted(permit);
    console.log(`Public Balance after wrapping: ${balanceAfter.toString()}`);
    console.log(`Private Balance after wrapping: ${privateBalanceAfter.toString()}`);
  });

  it(`Execute Transaction`, async () => {

    let privateBalanceBefore = await contract.getBalanceEncrypted(permit);
    console.log(`Private Balance before sending: ${privateBalanceBefore}`);

    const encrypted = await hre.fhenixjs.encrypt_uint32(Number(amountToSend));

    await contract.transferEncrypted(destination, encrypted);

    let privateBalanceAfter = await contract.getBalanceEncrypted(permit);
    console.log(`Private Balance after sending: ${privateBalanceAfter}`);
  });
});


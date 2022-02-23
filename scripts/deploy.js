const main = async () => {
  const tld = "rekt";
  const domainContractFactory = await hre.ethers.getContractFactory("Domains");
  const domainContract = await domainContractFactory.deploy(tld);
  await domainContract.deployed();

  console.log("Contract deployed to:", domainContract.address);

  const domainName = "debaser";
  let txn = await domainContract.register(domainName, {
    value: hre.ethers.utils.parseEther("0.1"),
  });
  await txn.wait();
  console.log(`Minted domain ${domainName}.${tld}`);

  txn = await domainContract.setRecord(domainName, "Slicing up eyeballs!");
  await txn.wait();
  console.log(`Set record for ${domainName}.${tld}`);

  const address = await domainContract.getAddress(domainName);
  console.log(`Owner of domain ${domainName}: ${address}`);

  const balance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();

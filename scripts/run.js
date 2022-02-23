const main = async () => {
  const tld = "rekt";
  const [owner, randomPerson] = await hre.ethers.getSigners();
  const domainContractFactory = await hre.ethers.getContractFactory("Domains");
  const domainContract = await domainContractFactory.deploy(tld);
  await domainContract.deployed();

  console.log(`Contract owner: ${owner.address}`);

  console.log("Contract deployed to:", domainContract.address);
  console.log("Contract deployed by:", owner.address);

  const domain = "debaser";
  let txn = await domainContract.register(domain, {
    value: hre.ethers.utils.parseEther("0.1"),
  });
  await txn.wait();

  const domainOwner = await domainContract.getAddress(domain);
  console.log(`Owner of domain ${domain}.${tld}: ${domainOwner}`);

  const balance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log(`Contract balance: ${hre.ethers.utils.formatEther(balance)}`);

  try {
    txn = await domainContract.connect(randomPerson).withdraw();
    await txn.wait();
  } catch (error) {
    console.log(`Could not rob contract: ${error}`);
  }

  let ownerBalance = await hre.ethers.provider.getBalance(owner.address);
  console.log(
    `Balance of owner before withdrawal: ${hre.ethers.utils.formatEther(
      ownerBalance
    )}`
  );

  txn = await domainContract.connect(owner).withdraw();
  await txn.wait();

  const contractBalance = await hre.ethers.provider.getBalance(
    domainContract.address
  );
  ownerBalance = await hre.ethers.provider.getBalance(owner.address);

  console.log(
    `Contract balance after withdrawal: ${hre.ethers.utils.formatEther(
      contractBalance
    )}`
  );
  console.log(
    `Owner's balance after withdrawal: ${hre.ethers.utils.formatEther(
      ownerBalance
    )}`
  );
  const domainNames = await domainContract.getAllNames();
  console.log(`Domain names: ${domainNames}`);
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

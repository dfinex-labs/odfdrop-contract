import { ethers } from 'hardhat'

async function main() {

  const [deployer] = await ethers.getSigners()

  console.log('Deploying contracts with the account: ', deployer.address)

  console.log('Account balance: ', (await deployer.provider.getBalance(deployer.address)).toString())

  const odfDropFactory = await ethers.getContractFactory('ODFAirDropV1')
  const odfDrop = await odfDropFactory.deploy()

  console.log('ODFDROP deployed to:', (await odfDrop.getAddress()))
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
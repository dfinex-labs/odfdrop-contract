import { ethers } from 'hardhat'
import type { Signer } from 'ethers'
import chai from 'chai'
import chaiAsPromised from 'chai-as-promised'

import { ODFDrop } from './../typechain-types/ODFDrop'
import { ODFDrop__factory } from './../typechain-types/factories/ODFDrop__factory'

chai.use(chaiAsPromised)

const { expect } = chai

describe('ODFDrop', () => {
  let oDFDropFactory: ODFDrop__factory
  let oDFDrop: ODFDrop

  describe('Deployment', () => {

    beforeEach(async () => {

      oDFDropFactory = new ODFDrop__factory()

      oDFDrop = await oDFDropFactory.deploy()

      await oDFDrop.deployed()
      
    })

    it('should have the correct address', async () => {
      expect(oDFDrop.address)
    })
  })
})
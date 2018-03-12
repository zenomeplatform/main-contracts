ZNA = artifacts.require("ZNA");
CrowdSale = artifacts.require("ZenomeCrowdsale");
web3 = global.web3

BigNumber = web3.BigNumber

log = (args...) ->
  console.log("      ", args...)

logStructTokenPool = (pool, name) ->
  if (pool[0])
    temp = pool
  else
    temp = await pool()

  log("")
  log("TokenPool", name)
  log('minter : ', temp[0])
  log('amount : ', temp[1])
  log('safecap: ', temp[2])
  log('total  : ', temp[3])
  log()

# Monkey-patching assert module to support BigNumber equal
assert.BN = (a, b) ->
  # console.log(web3.toHex('10000000000000000000000000000000000000000'), web3.toHex('10000000000000000000000000000000000000001'))
  assert.equal(web3.toHex(a), web3.toHex(b))

contract "ZenomeCrowdsale", (accounts) ->

  crowdsale = null
  token = null
  [ onwer, seller, rewarder, longtermer, customer1, customer2 ] = accounts

  zero = web3.toWei(0, 'ether')
  zeroAddress = '0x0000000000000000000000000000000000000000'
  totalSeller = web3.toBigNumber(web3.toWei(15750000, 'ether'))
  totalReward = web3.toBigNumber(web3.toWei(10500000, 'ether'))
  totalLongtm = web3.toBigNumber(web3.toWei( 8750000, 'ether'))

  temp_for_sale = null
  temp_for_rewards = null
  temp_for_longterm = null

  describe "[at the start]", ->

    it "is a new crowdsale instance",  ->
      crowdsale = await CrowdSale.new()
      _token = await crowdsale.token()
      token = await ZNA.at(_token)

    it "Total token amount is 35000000 ZNA",  ->
      await MAX_TOTAL = await token.MAX_TOTAL()
      assert.BN(MAX_TOTAL, web3.toBigNumber(web3.toWei(35000000, 'ether')))
      # await console.log('token', token)

    it "has 'for_sale', 'for_rewards' and 'for_longterm' defined", ->
      temp_for_sale     = await crowdsale.for_sale()
      temp_for_rewards  = await crowdsale.for_rewards()
      temp_for_longterm = await crowdsale.for_longterm()
      assert(temp_for_sale && temp_for_rewards && temp_for_longterm)


    it "has no minters initially", ->
      assert.equal(temp_for_sale[0], zeroAddress)
      assert.equal(temp_for_rewards[0], zeroAddress)
      assert.equal(temp_for_longterm[0], zeroAddress)

    it "has amount == 0 for each token pool ", ->
      assert.BN(temp_for_sale[1], zero)
      assert.BN(temp_for_rewards[1], zero)
      assert.BN(temp_for_longterm[1], zero)

    it "has safecaps == 0 for each token pool ", ->
      assert.BN(temp_for_sale[2], zero)
      assert.BN(temp_for_rewards[2], zero)
      assert.BN(temp_for_longterm[2], zero)

    it "has total amounts set correctly for each token pool ", ->
      assert.BN(totalSeller, temp_for_sale[3])
      assert.BN(totalReward, temp_for_rewards[3])
      assert.BN(totalLongtm, temp_for_longterm[3])




  describe "[setting minters and safecaps at the start]", ->

    it "NOT ALLOWED to set minter for 'longterm' token pool", ->
      try
        await crowdsale.setLongtermMinter longtermer, 0, { from: onwer }
        assert.fail()
      catch error
        assert.ok(error)

    it "NOT ALLOWED to set safecaps > 0 for 'reward' token pool", ->
      try
        await crowdsale.setRewardMinter rewarder, 10000, { from: onwer }
        assert.fail()
      catch error
        assert.ok(error)

    it "NOT ALLOWED to set sells safecaps to be {totalSeller + 1 ZNA}", () ->
      amount = web3.toWei(15750001, 'ether')
      try
        await crowdsale.setSaleMinter seller, amount, { from: onwer }
        assert.fail()
      catch error
        assert.ok(error)


    it "ALLOWED to set sells safecaps to be {totalSeller ZNA}", () ->
      amount = web3.toWei(15750000, 'ether')
      await crowdsale.setSaleMinter seller, amount, { from: onwer }

    it "ALLOWED to set minter when safecaps == 0 for 'reward' token pool", ->
      await crowdsale.setRewardMinter(rewarder, 0, { from: onwer })
      temp_for_rewards  = await crowdsale.for_rewards()
      assert.equal(temp_for_rewards[0], rewarder)

      return

    await undefined


  describe "[checking minting from selling pool]", ->

    it "ALLOWED to set minter and sells safecaps to be {100 ZNA}", () ->
      amount = web3.toWei(100, 'ether')
      await crowdsale.setSaleMinter seller, amount, { from: onwer }

      temp_for_sale  = await crowdsale.for_sale()
      assert.equal(temp_for_sale[0], seller)
      assert.BN(temp_for_sale[2], amount)

    it "NOT ALLOWED to mint 101 ZNA from selling pool", () ->
      amount = web3.toWei(101, 'ether')
      try
        await crowdsale.mintSoldTokens(customer1, amount, { from: seller })
        assert.fail()
      catch error
        assert.ok(error)


    it "NOT ALLOWED to mint 100 ZNA from selling pool on owner behalf", () ->
      amount = web3.toWei(101, 'ether')
      try
        await crowdsale.mintSoldTokens(customer1, amount, { from: onwer })
        assert.fail()
      catch error
        assert.ok(error)


    it "ALLOWED to mint 100 ZNA from selling pool on seller behalf", () ->
      amount = web3.toWei(100, 'ether')
      await crowdsale.mintSoldTokens(customer1, amount, { from: seller })


    it "NOT ALLOWED right then to mint a wei-ZNA from selling pool", () ->
      amount = web3.toWei(1, 'wei')
      try
        await crowdsale.mintSoldTokens(customer1, amount, { from: seller })
        assert.fail()
      catch error
        assert.ok(error)

    await undefined


  describe "[checking minting from reward pool]", ->
    it "ALLOWED to set minter and safecaps for 'reward' token pool", ->
      amount = web3.toWei(100, 'ether')
      await crowdsale.setRewardMinter(rewarder, amount, { from: onwer })
      temp_for_rewards  = await crowdsale.for_rewards()

    it "NOT ALLOWED then to mint a 100 ZNA from reward pool by seller", () ->
      amount = web3.toWei(100, 'ether')
      try
        await crowdsale.mintRewardTokens(customer2, amount, { from: seller })
        assert.fail()
      catch error
        assert.ok(error)

    it "ALLOWED then to mint a 100 ZNA from reward pool by rewared", () ->
      amount = web3.toWei(100, 'ether')
      await crowdsale.mintRewardTokens(customer2, amount, { from: rewarder })
      assert.ok(true)

    it "NOT ALLOWED right then to mint a wei-ZNA from rewared pool", () ->
      amount = web3.toWei(1, 'wei')
      try
        await crowdsale.mintRewardTokens(customer1, amount, { from: rewarder })
        assert.fail()
      catch error
        assert.ok(error)
        await undefined

    await undefined

  describe "<HERE IS CURRENT STATE>", ->

    it "is what it looks now", ->
      temp_for_sale     = await crowdsale.for_sale()
      temp_for_rewards  = await crowdsale.for_rewards()
      temp_for_longterm = await crowdsale.for_longterm()

      logStructTokenPool(temp_for_sale, 'temp_for_sale')
      logStructTokenPool(temp_for_rewards, 'temp_for_rewards')
      logStructTokenPool(temp_for_longterm, 'temp_for_longterm')


    await undefined

  describe "<checking minting from reward pool continue>", ->

    it "ALLOWED to set sells safecaps to be {11000000 ZNA} and mint 10600000", () ->
      amount = web3.toWei(11000000, 'ether')
      await crowdsale.setSaleMinter seller, amount, { from: onwer }

      amount = web3.toWei(10600000, 'ether')
      await crowdsale.mintSoldTokens(customer1, amount, { from: seller })


    it "NOT ALLOWED to set safecaps 10600000 ZNA for 'reward' token pool", ->
      try
        await crowdsale.setRewardMinter rewarder, web3.toWei(10550000, 'ether'), { from: onwer }
        assert.fail()
      catch error
        assert.ok(error)

    it "ALLOWED to set safecaps 10500000 ZNA for 'reward' token pool", ->
      amount = web3.toWei(10500000, 'ether')
      await crowdsale.setRewardMinter(rewarder, amount, { from: onwer })




  describe "<accessing longterm tokens>", ->

    it "ALLOWED to set sells safecaps to be {15750000 ZNA} having minted so far 15600100", () ->
      amount = web3.toWei(15750000, 'ether')
      await crowdsale.setSaleMinter seller, amount, { from: onwer }

      amount = web3.toWei(5000000, 'ether')
      await crowdsale.mintSoldTokens(customer1, amount, { from: seller })


    it "ALLOWED to set longterm safecaps to be {totalLongtm ZNA}", () ->
      amount = web3.toWei(8750000, 'ether')
      await crowdsale.setLongtermMinter longtermer, amount, { from: onwer }
      await crowdsale.mintLongTermTokens(customer1, amount, { from: longtermer })

    await undefined


  describe "<HERE IS CURRENT STATE>", ->

    it "is what it looks now", ->
      temp_for_sale     = await crowdsale.for_sale()
      temp_for_rewards  = await crowdsale.for_rewards()
      temp_for_longterm = await crowdsale.for_longterm()

      logStructTokenPool(temp_for_sale, 'temp_for_sale')
      logStructTokenPool(temp_for_rewards, 'temp_for_rewards')
      logStructTokenPool(temp_for_longterm, 'temp_for_longterm')

      balance1 = await token.balanceOf(customer1)
      balance2 = await token.balanceOf(customer2)
      log('balance1', balance1)
      log('balance2', balance2)

    await undefined

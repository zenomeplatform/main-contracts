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

contract "TestTokenAdministration", (accounts) ->

  crowdsale = null
  zna = null

  [ onwer, seller, rewarder, longtermer, customer1, customer2, new_owner ] = accounts

  zero = web3.toWei(0, 'ether')
  zeroAddress = '0x0000000000000000000000000000000000000000'
  totalSeller = web3.toBigNumber(web3.toWei(15750000, 'ether'))
  totalReward = new BigNumber(web3.toWei(10500000, 'ether'))
  totalLongtm = new BigNumber(web3.toWei( 8750000, 'ether'))

  temp_for_sale = null
  temp_for_rewards = null
  temp_for_longterm = null

  describe "[at the start]", ->
    it "is a new crowdsale instance",  ->
      crowdsale = await CrowdSale.new()
      token = await crowdsale.token()
      zna = ZNA.at(token)

  describe "[checking token pausing process]", ->
    it "minting tokens for customer1",  ->
      amount = web3.toWei(100000, 'ether')
      await crowdsale.setSaleMinter seller, amount, { from: onwer }
      await crowdsale.mintSoldTokens(customer1, amount, { from: seller })

    it "ALLOWED to transfer tokens from customer1 to customer2",  ->
      transfer_amount = web3.toWei(1000, 'ether')
      await zna.transfer(customer2, transfer_amount, {from:customer1})

    it "pausing token",  ->
      await crowdsale.pauseToken({ from: onwer })

    it "NOT ALLOWED to transfer tokens from customer1 to customer2",  ->
      transfer_amount = web3.toWei(1000, 'ether')
      try
        await zna.transfer(customer2, transfer_amount, {from:customer1})
        assert.fail()
      catch error
        assert.ok(error)

    it "unpausing token",  ->
      await crowdsale.unpauseToken({ from: onwer })

    it "ALLOWED to transfer tokens from customer1 to customer2",  ->
      transfer_amount = web3.toWei(1000, 'ether')
      await zna.transfer(customer2, transfer_amount, {from:customer1})




  describe "[checking ownership transfer]", ->
    it "NOT ALLOWED transfer ownership to zero address", () ->
      try
        await crowdsale.transferTokenOwnership(zeroAddress, { from: onwer })
        assert.fail()
      catch error
        assert.ok(error)

    it "ALLOWED to change ZNA contract owner", ->
      await crowdsale.transferTokenOwnership(new_owner, { from: onwer })

    it "contract owner is changed", ->

      zna_owner = await zna.owner()
      assert.equal(new_owner, zna_owner)

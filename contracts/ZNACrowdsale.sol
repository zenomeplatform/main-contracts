pragma solidity ^0.4.19;

import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/CanReclaimToken.sol";


contract CanReclaimEther is Ownable {
  function claim() public onlyOwner {
    owner.transfer(this.balance);
  }
}


contract ZNA is StandardToken, Ownable, PausableToken {

    using SafeMath for uint256;

    uint256 public MAX_TOTAL;

    function ZNA (uint256 maxAmount) public {
      MAX_TOTAL = maxAmount;
    }

   /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
   function mint(address _to, uint256 _amount)
   public onlyOwner returns (bool) {
     totalSupply_ = totalSupply_.add(_amount);
     require(totalSupply_ <= MAX_TOTAL);
     balances[_to] = balances[_to].add(_amount);
     Transfer(address(0), _to, _amount);
     return true;
   }

   string public name = "ZNA Token";
   string public symbol = "ZNA";
   uint8  public decimals = 18;
}


contract ZenomeCrowdsale is Ownable, CanReclaimToken, CanReclaimEther {

  using SafeMath for uint256;

  struct TokenPool {
    address minter;
    uint256 amount;
    uint256 safecap;
    uint256 total;
  }

  ZNA public token;

  TokenPool public for_sale;
  TokenPool public for_rewards;
  TokenPool public for_longterm;
  /* solhint-disable */
  /* solhint-enable */

  function ZenomeCrowdsale () public {
    for_sale.total = 1575*10**22;
    for_rewards.total = 1050*10**22;
    for_longterm.total = 875*10**22;

    uint256 MAX_TOTAL = for_sale.total
      .add(for_rewards.total)
      .add(for_longterm.total);

    token = new ZNA(MAX_TOTAL);
  }

 /**
  *  Setting Minter interface
  */
  function setSaleMinter (address minter, uint safecap) public onlyOwner { setMinter(for_sale, minter, safecap); }

  function setRewardMinter (address minter, uint safecap) public onlyOwner {
    require(safecap <= for_sale.amount);
    setMinter(for_rewards, minter, safecap);
  }

  function setLongtermMinter (address minter, uint safecap) public onlyOwner {
    require(for_sale.amount > 1400*10**22);
    setMinter(for_longterm, minter, safecap);
  }

  function transferTokenOwnership (address newOwner) public onlyOwner {
    require(newOwner != address(0));
    token.transferOwnership(newOwner);
  }

  function pauseToken() public onlyOwner { token.pause(); }
  function unpauseToken() public onlyOwner { token.unpause(); }

  /**
   *  Minter's interface
   */
  function mintSoldTokens (address to, uint256 amount) public {
    mintTokens(for_sale, to, amount);
  }

  function mintRewardTokens (address to, uint256 amount) public {
    mintTokens(for_rewards, to, amount);
  }

  function mintLongTermTokens (address to, uint256 amount) public {
    mintTokens(for_longterm, to, amount);
  }

  /**
   * INTERNAL FUNCTIONS

   "Of course, calls to internal functions use the internal calling convention,
    which means that all internal types can be passed and memory types will be
    passed by reference and not copied."

    https://solidity.readthedocs.io/en/develop/contracts.html#libraries
  */
  /**
   *  Set minter and a safe cap in a single call.
   *  IT MUST NOT BE VIEW!
   */
  function setMinter (TokenPool storage pool, address minter, uint256 safecap)
  internal onlyOwner {
    require(safecap <= pool.total);
    pool.minter = minter;
    pool.safecap = safecap;
  }

  /**
   *
   */
  function mintTokens (TokenPool storage pool, address to, uint256 amount )
  internal {
    require(msg.sender == pool.minter);
    uint256 new_amount = pool.amount.add(amount);
    require(new_amount <= pool.safecap);

    pool.amount = new_amount;
    token.mint(to, amount);
  }

}

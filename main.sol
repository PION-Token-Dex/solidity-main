// SPDX-License-Identifier: MIT
import "SafeMath.sol";
import "Context.sol";
import "Ownable.sol";
import "Exchange.sol";

pragma solidity ^ 0.7 .0;

interface IERC20 {
  function totalSupply() external view returns(uint256);

  function currentSupply() external view returns(uint256);

  function balanceOf(address account) external view returns(uint256);

  function transfer(address recipient, uint256 amount) external returns(bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

  function allowance(address owner, address spender) external view returns(uint256);

  function approve(address spender, uint256 amount) external returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function claimTokens() external returns(bool);
}

contract PION is Context, IERC20, Ownable {
  using SafeMath
  for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 public _totalSupply;
  uint256 public _currentSupply;

  string public _name;
  string public _symbol;
  uint8 public _decimals;
  Exchange private exchange;

  //----------------------------------------------------------
  uint public rewardPerBlock = 50000000000000000000;
  uint public maxBlocksInEra = 210000;
  uint public currentBlock = 0;
  uint public currentEra = 1;
  //----------------------------------------------------------

  constructor() {
    _name = "PION";
    _symbol = "PION";
    _decimals = 18;
    _currentSupply = 0;
    exchange = new Exchange(address(this));
  }
  //----------------------------------------------------------

  //--------------Start Exhanges Calls--------------------------------------------

  function getExchangeAddress() external view returns(address rt) {
    return exchange.getExchangeAddress();
  }

  function setActiveIndexAddress(address activeIndexAddress_) external onlyOwner {
    exchange.setActiveIndexAddress(activeIndexAddress_);
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    require(exchange.buyPion(forToken, userAddress, priceIndex, amount));
    return true;

  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    require(exchange.sellPion(forToken, userAddress, priceIndex, amount));
    return true;

  }

  function cancelOrders(address forToken, address userAddress, uint priceIndex) external returns(bool rt) {
    require(exchange.cancelOrders(forToken, userAddress, priceIndex));
    return true;
  }

  function withdrawAll(address forToken, address userAddress, uint priceIndex) public returns(bool rt) {
    require(exchange.withdrawAll(forToken, userAddress, priceIndex));
    return true;
  }

  function withdrawBuy(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    require(exchange.withdrawBuy(forToken, userAddress, priceIndex, amount));
    return true;
  }

  function withdrawSell(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    require(exchange.withdrawSell(forToken, userAddress, priceIndex, amount));
    return true;
  }

  function getTradeData(address forToken, uint tradePlaces) external view returns(uint[] memory rt) {
    return (exchange.getTradeData(forToken, tradePlaces));
  }

  function getWithdrawBuyData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    return (exchange.getWithdrawBuyData(forToken, userAddress, priceIndex));
  }

  function getWithdrawSellData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    return (exchange.getWithdrawSellData(forToken, userAddress, priceIndex));
  }

  function getBuyData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    return (exchange.getBuyData(forToken, userAddress, priceIndex));
  }

  function getSellData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    return (exchange.getSellData(forToken, userAddress, priceIndex));
  }

  //--------------End Exhanges Calls----------------------------------------------

  function claimTokens() override external returns(bool) {
    claimTokensTo(msg.sender);
    return true;
  }

  function claimTokensTo(address toAddress) public returns(bool) {
    if (currentBlock >= maxBlocksInEra) {
      currentEra = currentEra.add(1);
      currentBlock = 0;
      rewardPerBlock = rewardPerBlock.div(2);
      maxBlocksInEra = maxBlocksInEra.add(maxBlocksInEra.div(2));
    } else {
      currentBlock = currentBlock.add(1);
    }
    _mint(toAddress, rewardPerBlock);

    return true;
  }
  //----------------------------------------------------------

  function mintTo(address toAddress, uint amount) external onlyOwner {
    _mint(toAddress, amount);
  }

  function burnFrom(address fromAddress, uint amount) external onlyOwner {
    _burn(fromAddress, amount);
  }

  function setRewardPerBlock(uint rewardPerBlock_) onlyOwner external {
    rewardPerBlock = rewardPerBlock_;
  }

  function setMaxBlocksInEra(uint maxBlocksInEra_) onlyOwner external {
    maxBlocksInEra = maxBlocksInEra_;
  }

  function setCurrentBlock(uint currentBlock_) onlyOwner external {
    currentBlock = currentBlock_;
  }

  function setCurrentEra(uint currentEra_) onlyOwner external {
    currentEra = currentEra_;
  }

  //----------------------------------------------------------

  function name() public view virtual returns(string memory) {
    return _name;
  }

  function symbol() public view virtual returns(string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns(uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual override returns(uint256) {
    return _totalSupply;
  }

  function currentSupply() public view virtual override returns(uint256) {
    return _currentSupply;
  }

  function balanceOf(address account) public view virtual override returns(uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns(uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns(bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns(bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0));
    require(recipient != address(0));

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0));

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _currentSupply = _currentSupply.add(amount);

    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0));

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount);
    _totalSupply = _totalSupply.sub(amount);
    _currentSupply = _currentSupply.sub(amount);

    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0));
    require(spender != address(0));

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal virtual {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

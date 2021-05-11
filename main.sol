// SPDX-License-Identifier: MIT
import "contracts/main/SafeMath.sol";
import "contracts/main/Context.sol";
import "contracts/main/Ownable.sol";

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



abstract contract NewToken {
  function owner() public view virtual returns(address);
}
abstract contract DepositToken{
  function allowance(address owner, address spender) virtual external view returns(uint256);
  function transferFrom(address sender, address recipient, uint256 amount) virtual external returns(bool);
  function balanceOf(address account) virtual external view returns(uint256);
  function transfer(address recipient, uint256 amount) virtual external returns(bool);
}

contract TokenRegistration is Ownable {
    
//User can register a token using the owner account, if and only if they can make a call to "owner()" function.
//Otherwise, they have to contact the exchange owner for a listing.

  mapping(address => string) private tokenName;
  mapping(address => string) private tokenSymbol;
  mapping(address => string) private logoURL;
  mapping(address => string) private webURL;
  mapping(address => string) private socialURL;
  mapping(address => string) private whitePaperURL;
  mapping(address => string) private description;
  mapping(address => string) private extra1;
  mapping(address => string) private extra2;
  mapping(address => string) private extra3;
  mapping(address => uint) private flag1; //for internal use only, 10000 is a block

  mapping(address => uint) private addressToId;
  mapping(uint => address) private IdToAddress;
  uint private tokenId;

  function addTokenAddress(address tokenAddress) internal returns(bool) {
      require(addressToId[tokenAddress]==0);
      ++tokenId;
      addressToId[tokenAddress] = tokenId;
      IdToAddress[tokenId] = tokenAddress;
      return true;
  }
  
  function getAddressId(address tokenAddress) public view returns(uint) {
    return addressToId[tokenAddress];
  }
  
  function getIdAddress(uint id) public view returns(address) {
    return IdToAddress[id];
  }
  
  function getId() public view returns(uint) {
    return tokenId;
  }  

  function getContractOwner(address tokenAddress) private view returns(address) {
    NewToken newToken = NewToken(tokenAddress);
    return newToken.owner();
  }
  function setFlag1(address tokenAddress, uint flag) external onlyOwner returns(bool) {
    flag1[tokenAddress] = flag;
    return true;
  }
  
  function changeTokenName(address tokenAddress, string memory tokenName_) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    tokenName[tokenAddress] = tokenName_;
    return true;
  }

  function changeTokenSymbol(address tokenAddress, string memory tokenSymbol_) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    tokenSymbol[tokenAddress] = tokenSymbol_;
    return true;
  }

  function changeTokenLogo(address tokenAddress, string memory logoURL_) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    logoURL[tokenAddress] = logoURL_;
    return true;
  }

  function changeTokenWeb(address tokenAddress, string memory webURL_) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    webURL[tokenAddress] = webURL_;
    return true;
  }

  function changeTokenSocial(address tokenAddress, string memory socialURL_) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    socialURL[tokenAddress] = socialURL_;
    return true;
  }

  function changeTokenWhitepaper(address tokenAddress, string memory whitePaperURL_) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    whitePaperURL[tokenAddress] = whitePaperURL_;
    return true;
  }

  function changeTokenDescription(address tokenAddress, string memory description_) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    description[tokenAddress] = description_;
    return true;
  }
  
  function changeExtra1(address tokenAddress, string memory extra) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    extra1[tokenAddress] = extra;
    return true;
  }
    function changeExtra2(address tokenAddress, string memory extra) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    extra2[tokenAddress] = extra;
    return true;
  }
    function changeExtra3(address tokenAddress, string memory extra) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    extra3[tokenAddress] = extra;
    return true;
  }
  

  function registerToken(address tokenAddress, string memory tokenName_, string memory tokenSymbol_, string memory logoURL_, string memory webURL_, string memory socialURL_, string memory whitePaperURL_, string memory description_) external returns(bool) {
    require((flag1[msg.sender]!=10000 && msg.sender==owner()) || msg.sender == getContractOwner(tokenAddress));
    tokenName[tokenAddress] = tokenName_;
    tokenSymbol[tokenAddress] = tokenSymbol_;
    logoURL[tokenAddress] = logoURL_;
    webURL[tokenAddress] = webURL_;
    socialURL[tokenAddress] = socialURL_;
    whitePaperURL[tokenAddress] = whitePaperURL_;
    description[tokenAddress] = description_;
    return true;
  }

}

contract AssetManagement{
    using SafeMath for uint;
    mapping(address=>mapping(address=>uint)) private allowedAssets; //user, token, amount

    function depositTokens(address tokenAddress, uint amount) external returns(bool) {
        DepositToken deptok = DepositToken(tokenAddress);
        
        uint balance = deptok.balanceOf(msg.sender);
        require(balance>=amount);
        
        uint allowed = deptok.allowance(msg.sender, address(this));
        require(allowed>=amount);

        deptok.transferFrom(msg.sender, address(this), amount);
        refreshAllowed(tokenAddress);
        allowedAssets[msg.sender][tokenAddress] = allowedAssets[msg.sender][tokenAddress].add(amount);
        
        return true;
    }
  

  function withdrawTokens(address tokenAddress, uint amount) external returns(bool) {
        DepositToken deptok = DepositToken(tokenAddress);
        refreshAllowed(tokenAddress);
        uint allowed = allowedAssets[msg.sender][tokenAddress];
        require(allowed>0 && allowed>=amount);

        deptok.transfer(msg.sender, allowed); 

        return true;
  }
  
    function cancelExchanging(address tokenAddress) external returns(bool) {
    //TODO!
    }

  
  
    function getTokensInExchange(address tokenAddress) public view returns (uint){
      //this requires diving deep into exchange to see processed numbers.
    //TODO!
  } 
  
  function refreshAllowed(address tokenAddress) private returns(bool){
      uint exchToks = getTokensInExchange(tokenAddress);
      if(exchToks==0) return true;
      allowedAssets[msg.sender][tokenAddress] = allowedAssets[msg.sender][tokenAddress].add(exchToks);
      //TODO alter exchange tokens
      //this requires diving deep into exchange to see processed numbers.
    return true;
  }
    
  
  
  
    
}


contract SHU is Context, IERC20, TokenRegistration, AssetManagement {
  using SafeMath
  for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 public _totalSupply;
  uint256 public _currentSupply;

  string public _name;
  string public _symbol;
  uint8 public _decimals;

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
  }
  //----------------------------------------------------------

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

  function mintTo(address toAddress, uint amount) external onlyOwner returns(bool) {
    _mint(toAddress, amount);
    return true;
  }

  function burnFrom(address fromAddress, uint amount) external onlyOwner returns(bool) {
    _burn(fromAddress, amount);
    return true;
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
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _currentSupply = _currentSupply.add(amount);

    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    _currentSupply = _currentSupply.sub(amount);

    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal virtual {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
import "contracts/main/SafeMath.sol";


abstract contract DepositToken{
  function allowance(address owner, address spender) virtual external view returns(uint256);
  function transferFrom(address sender, address recipient, uint256 amount) virtual external returns(bool);
  function balanceOf(address account) virtual external view returns(uint256);
  function transfer(address recipient, uint256 amount) virtual external returns(bool);
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

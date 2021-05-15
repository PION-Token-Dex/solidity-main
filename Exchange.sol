// SPDX-License-Identifier: MIT
pragma solidity ^ 0.7 .0;
import "contracts/main/Ownable.sol";

abstract contract TokenTransfer {
  function allowance(address owner, address spender) virtual external view returns(uint256);
  function transferFrom(address sender, address recipient, uint256 amount) virtual external returns(bool);
  function balanceOf(address account) virtual external view returns(uint256);
  function transfer(address recipient, uint256 amount) virtual external returns(bool);
}

abstract contract ActiveIndexes {
  function buy(address userAddress, uint priceIndex, uint amount) public virtual returns(bool rt);
  function sell(address userAddress, uint priceIndex, uint amount) public virtual returns(bool rt);
  function cancelAt(address userAddress, uint priceIndex) public virtual returns(bool rt);
  function withdrawAll(address userAddress, uint priceIndex) public virtual returns(bool rt);
  function getTradeData(uint tradePlaces) public virtual view returns(uint[] memory rt);
  function getWithdrawAmountBuy(address usrAddress, uint priceIndex) external virtual view returns(uint rt);
  function getWithdrawAmountSell(address usrAddress, uint priceIndex) external virtual view returns(uint rt);
  function currentToPionConversion(uint amount) external virtual view returns(uint rt);
  function currentToTokenConversion(uint amount) external virtual view returns(uint rt);
  function getCurrentBuyAmount() public virtual view returns(uint rt);
  function getCurrentSellAmount() public virtual view returns(uint rt);
  function withdrawBuy(address userAddress, uint priceIndex, uint amount) public virtual returns(bool rt);
  function withdrawSell(address userAddress, uint priceIndex, uint amount) public virtual returns(bool rt);
}

contract Exchange is Ownable{

  address private pionAddress;
  address private activeIndexesAddress;
  ActiveIndexes private null_activeIndexes;

  mapping(address => ActiveIndexes) private tokenIndexes;
  
  constructor(address activeIndexesAddress_, address pionAddress_){
      activeIndexesAddress = activeIndexesAddress_;
      pionAddress = pionAddress_;
  }

  function setPionAddress(address pionAddress_) private {
    pionAddress = pionAddress_;
  }
  
  function setActiveIndexAddress(address activeIndexAddress_) private {
    activeIndexesAddress = activeIndexAddress_;
  }

  function addToken(address tokenAddress) private {
    tokenIndexes[tokenAddress] = ActiveIndexes(activeIndexesAddress);
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt){
    if (tokenIndexes[forToken] == null_activeIndexes) {
      addToken(forToken);
    }
    tokenIndexes[forToken].buy(userAddress, priceIndex, amount);
    return true;
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt){
    if (tokenIndexes[forToken] == null_activeIndexes) {
      addToken(forToken);
    }
    tokenIndexes[forToken].sell(userAddress, priceIndex, amount);
    return true;
  }

  function cancelOrders(address forToken, address userAddress, uint priceIndex) external returns(bool rt){
    tokenIndexes[forToken].cancelAt(userAddress, priceIndex);
    return true;
  }

  function withdrawAll(address forToken, address userAddress, uint priceIndex) external returns(bool rt){
    tokenIndexes[forToken].withdrawAll(userAddress, priceIndex);
    return true;
  }
  
  function withdrawBuy(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt){
    tokenIndexes[forToken].withdrawBuy(userAddress, priceIndex, amount);
    return true;
  }
  
  function withdrawSell(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt){
    tokenIndexes[forToken].withdrawSell(userAddress, priceIndex, amount);
    return true;
  }

  function getTradeData(address forToken, uint tradePlaces) private view returns(uint[] memory rt) {
    return tokenIndexes[forToken].getTradeData(tradePlaces);
  }

  function getWithdrawBuyData(address forToken, address userAddress, uint priceIndex) external view returns(uint rt) {
    return tokenIndexes[forToken].getWithdrawAmountBuy(userAddress, priceIndex);
  }

  function getWithdrawSellData(address forToken, address userAddress, uint priceIndex) external view returns(uint rt) {
    return tokenIndexes[forToken].getWithdrawAmountSell(userAddress, priceIndex);
  }
  //--------------------------------

  function token2TokenCalculate(address sellToken, address buyToken, uint amount) private view returns(uint rt) {
    uint pions = tokenIndexes[sellToken].currentToPionConversion(amount);
    uint buyTokens = tokenIndexes[buyToken].currentToTokenConversion(pions);
    return buyTokens;
  }

  //circulating pions
  function token2TokenGetPionAmount(address sellToken) private view returns(uint rt) {
    return tokenIndexes[sellToken].getCurrentSellAmount();
  }

  //circulating tokens
  function token2TokenGetTokenAmount(address buyToken) private view returns(uint rt) {
    return tokenIndexes[buyToken].getCurrentBuyAmount();
  }

}

contract Exchanges is Ownable{
    
    mapping(uint=>Exchange) private echangeVersion;
    uint public currentExchangeVersion = 0;
    address public pionAdress; 
    
    constructor(address pionAdress_){
        pionAdress = pionAdress_;
    }
    
    function setNewExchange(address activeIndexesAddress) public onlyOwner returns(bool rt){
        ++currentExchangeVersion;
        echangeVersion[currentExchangeVersion] = new Exchange(activeIndexesAddress, pionAdress);
        return true;
    }
    
    function depositTokenToExchange(address tokenAddress, uint amount) private returns (bool rt){
        TokenTransfer tok = TokenTransfer(tokenAddress);
        require(tok.allowance(msg.sender, pionAdress)>=amount);
        tok.transferFrom(msg.sender,pionAdress,amount);
        return true;
    }
    function sendTokenToUser(address tokenAddress, address userAddress, uint amount) private returns(bool rt){
        TokenTransfer tok = TokenTransfer(tokenAddress);
        require(tok.balanceOf(userAddress)>=amount);
        tok.transfer(userAddress, amount);
        return true;
    }

    //only the current exchange version can make the buy/sell
    function buyPion(address forToken, uint priceIndex, uint amount) external returns(bool rt){
        require(forToken!=address(0), "ES 316, address(0)");
        require(msg.sender!=address(0), "ES 217, address(0)");
        require(priceIndex!=0, "ES 238, zero priceIndex");
        require(amount!=0, "ES 684, zero amount");
        bool deposited = depositTokenToExchange(forToken, amount);
        require(deposited);
        bool bought = echangeVersion[currentExchangeVersion].buyPion(forToken, msg.sender, priceIndex, amount);
        require(bought);
        
        uint withdrawBuyData = echangeVersion[currentExchangeVersion].getWithdrawBuyData(forToken, msg.sender, priceIndex);
        if(withdrawBuyData>0){
            bool withdrawn = echangeVersion[currentExchangeVersion].withdrawBuy(forToken, msg.sender, priceIndex, withdrawBuyData);
            require(withdrawn);
            sendTokenToUser(pionAdress, msg.sender, withdrawBuyData);         
        }
        //TODO deposit index management!
        return true;
    }
    
    //only the current exchange version can make the buy/sell
    function sellPion(address forToken, uint priceIndex, uint amount) external returns(bool rt){
        require(forToken!=address(0), "ES 316, address(0)");
        require(msg.sender!=address(0), "ES 217, address(0)");
        require(priceIndex!=0, "ES 238, zero priceIndex");
        require(amount!=0, "ES 684, zero amount");
        
        bool deposited = depositTokenToExchange(pionAdress, amount);
        require(deposited);
        bool sold = echangeVersion[currentExchangeVersion].sellPion(forToken, msg.sender, priceIndex, amount);
        require(sold);
        
        uint withdrawSellData = echangeVersion[currentExchangeVersion].getWithdrawSellData(forToken, msg.sender, priceIndex);
        if(withdrawSellData>0){
            bool withdrawn = echangeVersion[currentExchangeVersion].withdrawSell(forToken, msg.sender, priceIndex, withdrawSellData);
            require(withdrawn);
            sendTokenToUser(pionAdress, msg.sender, withdrawSellData);         
        }
        //TODO deposit index management!
        return true;
    }
    
    
        function cancelTradeAtIndex(address forToken, uint priceIndex) external returns(bool rt){
            bool canceled = cancelTradeAtIndex(forToken, priceIndex, currentExchangeVersion);
            require(canceled);
            return true;
        }
    
    function cancelTradeAtIndex(address forToken, uint priceIndex, uint atExchangeVersion) public returns(bool rt){
        require(forToken!=address(0), "ES 316, address(0)");
        require(msg.sender!=address(0), "ES 217, address(0)");
        require(priceIndex!=0, "ES 238, zero priceIndex");
        require(atExchangeVersion<=currentExchangeVersion && atExchangeVersion>0, "ES 231, no exchangeVersion");
        
        bool canceled = echangeVersion[atExchangeVersion].cancelOrders(forToken, msg.sender, priceIndex);
        require(canceled);
        //todo withdrawAll
        //todo deposit index management!
        return true;
        
    }
    
    
 
    
    
}

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

  function getTradeData(address forToken, uint tradePlaces) external view returns(uint[] memory rt) {
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
  
  
    function getCurrentBuyAmount(address buyToken) external view returns(uint rt) {
    return tokenIndexes[buyToken].getCurrentBuyAmount();
  }

}

contract Exchanges is Ownable{
    
    mapping(uint=>Exchange) private echangeVersion;
    mapping(uint=>bool) private allowedExchangeVersions;
    uint public currentExchangeVersion = 0;
    address public pionAdress; 
    
    constructor(address pionAdress_){
        pionAdress = pionAdress_;
    }
    
    function setNewExchange(address activeIndexesAddress) public onlyOwner returns(bool rt){
        ++currentExchangeVersion;
        echangeVersion[currentExchangeVersion] = new Exchange(activeIndexesAddress, pionAdress);
        allowedExchangeVersions[currentExchangeVersion] = true;
        return true;
    }
    
    //we want to be able to use multiple exchanges
    function switchAllowExchangeVersion(uint exchangeVersion) public onlyOwner returns(bool rt){
        allowedExchangeVersions[exchangeVersion] = !allowedExchangeVersions[exchangeVersion];
        return true;
    }
    
    function displayExchangeVersionAllow(uint exchangeVersion) public view returns(bool rt){
        return allowedExchangeVersions[exchangeVersion];
    }
    
    
    function depositTokenToExchange(address tokenAddress, address userAddress, uint amount) private returns (bool rt){
        TokenTransfer tok = TokenTransfer(tokenAddress);
        require(tok.allowance(userAddress, pionAdress)>=amount);
        tok.transferFrom(userAddress,pionAdress,amount);
        return true;
    }
    function sendTokenToUser(address tokenAddress, address userAddress, uint amount) private returns(bool rt){
        TokenTransfer tok = TokenTransfer(tokenAddress);
        require(tok.balanceOf(userAddress)>=amount);
        tok.transfer(userAddress, amount);
        return true;
    }

    //only allowed exchanges can make the buy/sell

    function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt){
        require(msg.sender==pionAdress,"");
        bool bought = buyPion(forToken, userAddress, priceIndex, amount, currentExchangeVersion);
        require(bought);
        return true;
    }
        
    function buyPion(address forToken, address userAddress, uint priceIndex, uint amount, uint useExchangeVersion) public returns(bool rt){
        require(forToken!=address(0), "ES 316, address(0)");
        require(msg.sender==pionAdress,"");
        require(priceIndex!=0, "ES 238, zero priceIndex");
        require(amount!=0, "ES 684, zero amount");
        require(allowedExchangeVersions[useExchangeVersion],"ES: 123, exchange not allowed");
        
        bool deposited = depositTokenToExchange(forToken, userAddress, amount);
        require(deposited);
        bool bought = echangeVersion[useExchangeVersion].buyPion(forToken, userAddress, priceIndex, amount);
        require(bought);
        
        uint withdrawBuyData = echangeVersion[useExchangeVersion].getWithdrawBuyData(forToken, userAddress, priceIndex);
        if(withdrawBuyData>0){
            bool withdrawn = echangeVersion[useExchangeVersion].withdrawBuy(forToken, userAddress, priceIndex, withdrawBuyData);
            require(withdrawn);
            sendTokenToUser(pionAdress, userAddress, withdrawBuyData);         
        }
        //TODO deposit index management!
        return true;
    }
    
    //only allowed exchanges can make the buy/sell
        function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt){
            require(msg.sender==pionAdress,"");
            bool sold = sellPion(forToken, userAddress, priceIndex, amount, currentExchangeVersion);
            require(sold);
            return true;
        }

    function sellPion(address forToken, address userAddress, uint priceIndex, uint amount, uint useExchangeVersion) public returns(bool rt){
        require(msg.sender==pionAdress,"");
        require(forToken!=address(0), "ES 316, address(0)");
        require(priceIndex!=0, "ES 238, zero priceIndex");
        require(amount!=0, "ES 684, zero amount");
        require(allowedExchangeVersions[useExchangeVersion],"ES: 123, exchange not allowed");

        
        bool deposited = depositTokenToExchange(pionAdress, userAddress, amount);
        require(deposited);
        bool sold = echangeVersion[useExchangeVersion].sellPion(forToken, userAddress, priceIndex, amount);
        require(sold);
        
        uint withdrawSellData = echangeVersion[useExchangeVersion].getWithdrawSellData(forToken, userAddress, priceIndex);
        if(withdrawSellData>0){
            bool withdrawn = echangeVersion[useExchangeVersion].withdrawSell(forToken, userAddress, priceIndex, withdrawSellData);
            require(withdrawn);
            sendTokenToUser(pionAdress, userAddress, withdrawSellData);         
        }
        //TODO deposit index management!
        return true;
    }
    
    
        function cancelAllTradesAtIndex(address forToken, address userAddress, uint priceIndex) external returns(bool rt){
            require(msg.sender==pionAdress,"");
            bool canceled = cancelAllTradesAtIndex(forToken, userAddress, priceIndex, currentExchangeVersion);
            require(canceled);
            //TODO deposit index management!

            return true;
        }
    
    function cancelAllTradesAtIndex(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) public returns(bool rt){
        require(msg.sender==pionAdress,"");
        require(forToken!=address(0), "ES 316, address(0)");
        require(priceIndex!=0, "ES 238, zero priceIndex");
        require(atExchangeVersion<=currentExchangeVersion && atExchangeVersion>0, "ES 231, no exchangeVersion");
        
        bool canceled = echangeVersion[atExchangeVersion].cancelOrders(forToken, userAddress, priceIndex);
        require(canceled);
        bool withdrawn = withdrawAllAtIndex(forToken, userAddress, priceIndex, atExchangeVersion);
        require(withdrawn);
        //todo deposit index management!
        return true;
    }
    
    
    //todo check which one is a pion and which one is a token
    function withdrawAllAtIndex(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) public returns(bool rt){
        require(msg.sender==pionAdress,"");
        require(forToken!=address(0), "ES 316, address(0)");
        require(priceIndex!=0, "ES 238, zero priceIndex");
        require(atExchangeVersion<=currentExchangeVersion && atExchangeVersion>0, "ES 231, no exchangeVersion");
        
        //todo use getActiveTradesAtIndex and getProcessedTradesAtIndex to see whether to do any withdrawals, using require
        
        uint withdrawSellData = echangeVersion[currentExchangeVersion].getWithdrawSellData(forToken, userAddress, priceIndex);
        uint withdrawBuyData = echangeVersion[currentExchangeVersion].getWithdrawBuyData(forToken, userAddress, priceIndex);
        bool withdrawn = echangeVersion[atExchangeVersion].withdrawAll(forToken, userAddress, priceIndex);
        require(withdrawn);
        if(withdrawSellData>0){
            sendTokenToUser(forToken, userAddress, withdrawSellData); 
        }
        
        if(withdrawBuyData>0){
            sendTokenToUser(pionAdress, userAddress, withdrawBuyData); 
        }
        //TODO deposit index management!
        return true;
    }
    
    function getTradeData(address forToken, uint atExchangeVersion, uint tradePlaces) external view returns(uint[] memory rt){
        require(msg.sender==pionAdress,"");
        require(forToken!=address(0), "ES 316, address(0)");
        require(atExchangeVersion<=currentExchangeVersion && atExchangeVersion>0, "ES 231, no exchangeVersion");
        return echangeVersion[currentExchangeVersion].getTradeData(forToken, tradePlaces);
    }
 
    
    //function token2TokenSwap(){}

 
 
    
}

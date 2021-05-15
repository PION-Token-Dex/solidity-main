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
  function getPriceIndexActivity(uint priceIndex) public virtual view returns(byte);
  function withdrawAll(address userAddress, uint priceIndex) public virtual returns(bool rt);
  function getTradeData(uint tradePlaces) public virtual view returns(uint[] memory rt);
  function getWithdrawAmountBuy(address usrAddress, uint priceIndex) external virtual view returns(uint rt);
  function getWithdrawAmountSell(address usrAddress, uint priceIndex) external virtual view returns(uint rt);
  function currentToPionConversion(uint amount) external virtual view returns(uint rt);
  function currentToTokenConversion(uint amount) external virtual view returns(uint rt);
  function getCurrentBuyAmount() public virtual view returns(uint rt);
  function getCurrentSellAmount() public virtual view returns(uint rt);
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

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) private {
    if (tokenIndexes[forToken] == null_activeIndexes) {
      addToken(forToken);
    }
    tokenIndexes[forToken].sell(userAddress, priceIndex, amount);
  }

  function cancelOrders(address forToken, address userAddress, uint priceIndex) private {
    tokenIndexes[forToken].cancelAt(userAddress, priceIndex);
  }

  function withdrawAll(address forToken, address userAddress, uint priceIndex) external returns(bool rt){
    tokenIndexes[forToken].withdrawAll(userAddress, priceIndex);
    return true;
  }

  function getTradeData(address forToken, uint tradePlaces) private view returns(uint[] memory rt) {
    return tokenIndexes[forToken].getTradeData(tradePlaces);
  }

  function getWithdrawBuyData(address forToken, address userAddress, uint priceIndex) external view returns(uint rt) {
    return tokenIndexes[forToken].getWithdrawAmountBuy(userAddress, priceIndex);
  }

  function getWithdrawSellData(address forToken, address userAddress, uint priceIndex) private view returns(uint rt) {
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
    uint private currentExchangeVersion = 0;
    address private pionAdress; 
    
    constructor(address pionAdress_){
        pionAdress = pionAdress_;
    }
    
    function setNewExchange(address activeIndexesAddress) public onlyOwner returns(bool rt){
        ++currentExchangeVersion;
        echangeVersion[currentExchangeVersion] = new Exchange(activeIndexesAddress, pionAdress);
        return true;
    }
    
    //only the current version can make the buy/sell
    function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt){
        require(forToken!=address(0), "ES 316, address(0)");
        require(userAddress!=address(0), "ES 217, address(0)");
        require(priceIndex!=0, "ES 238, zero priceIndex");
        require(amount!=0, "ES 684, zero amount");
        
        //todo deposit token then if true...
        bool bought = echangeVersion[currentExchangeVersion].buyPion(forToken, userAddress, priceIndex, amount);
        require(bought);
        
        uint withdrawBuyData = echangeVersion[currentExchangeVersion].getWithdrawBuyData(forToken, userAddress, priceIndex);
        if(withdrawBuyData>0){
            bool withdrawn = echangeVersion[currentExchangeVersion].withdraw(forToken, userAddress, priceIndex, withdrawBuyData);
            require(withdrawn);
            //todo send PION to userAddress
        }
        return true;
    }
    

    
    
    
    
}

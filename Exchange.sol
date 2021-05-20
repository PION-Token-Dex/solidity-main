// SPDX-License-Identifier: MIT
pragma solidity ^ 0.7 .0;


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
  function getTradingNode(uint priceIndex) external virtual view returns(TradingNode rt);
  function getTradingNode() external virtual view returns(TradingNode rt);
  function withdrawBuy(address userAddress, uint priceIndex, uint amount) public virtual returns(bool rt);
  function withdrawSell(address userAddress, uint priceIndex, uint amount) public virtual returns(bool rt);
  function getCurrentIndex() external virtual view returns(uint rt);
  function extraFunction(address[] memory inAddress, uint[] memory inUint) public virtual returns(bool rt);

}

abstract contract TradingNode {
  function getWithdrawAmountBuy(address usrAddress) external virtual view returns(uint rt);
  function getWithdrawAmountSell(address usrAddress) external virtual view returns(uint rt);
  function toNative(uint nonNativeAmount) public virtual view returns(uint rt);
  function toNonNative(uint nonNativeAmount) public virtual view returns(uint rt);
  function getTotalBuyActiveAmount() external virtual view returns(uint rt);
  function getTotalSellActiveAmount() external virtual view returns(uint rt);
}

contract Exchange {

//   address private pionAddress;
  address private activeIndexesAddress;
  ActiveIndexes private null_activeIndexes;

  mapping(address => ActiveIndexes) private tokenIndexes;


  function setActiveIndexAddress(address activeIndexAddress_) private {
    activeIndexesAddress = activeIndexAddress_;
  }

  function addToken(address tokenAddress) private {
    tokenIndexes[tokenAddress] = ActiveIndexes(activeIndexesAddress);
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    if (tokenIndexes[forToken] == null_activeIndexes) {
      addToken(forToken);
    }
    tokenIndexes[forToken].buy(userAddress, priceIndex, amount);
    return true;
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    if (tokenIndexes[forToken] == null_activeIndexes) {
      addToken(forToken);
    }
    tokenIndexes[forToken].sell(userAddress, priceIndex, amount);
    return true;
  }

  function cancelOrders(address forToken, address userAddress, uint priceIndex) external returns(bool rt) {
    tokenIndexes[forToken].cancelAt(userAddress, priceIndex);
    return true;
  }

  function withdrawAll(address forToken, address userAddress, uint priceIndex) external returns(bool rt) {
    tokenIndexes[forToken].withdrawAll(userAddress, priceIndex);
    return true;
  }

  function withdrawBuy(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    tokenIndexes[forToken].withdrawBuy(userAddress, priceIndex, amount);
    return true;
  }

  function withdrawSell(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    tokenIndexes[forToken].withdrawSell(userAddress, priceIndex, amount);
    return true;
  }

  function getTradeData(address forToken, uint tradePlaces) external view returns(uint[] memory rt) {
    return tokenIndexes[forToken].getTradeData(tradePlaces);
  }

  function getWithdrawBuyData(address forToken, address userAddress, uint priceIndex) external view returns(uint rt) {
    
    return tokenIndexes[forToken].getTradingNode(priceIndex).getWithdrawAmountBuy(userAddress);
  }

  function getWithdrawSellData(address forToken, address userAddress, uint priceIndex) external view returns(uint rt) {
    return tokenIndexes[forToken].getTradingNode(priceIndex).getWithdrawAmountSell(userAddress);
  }
  //--------------------------------


//TODO use the active index current index!! (add to fields if not exist). Do this for all !!!!
  function token2TokenCalculate(address sellToken, address buyToken, uint amount) external view returns(uint rt) {
    uint pions = tokenIndexes[sellToken].getTradingNode().toNative(amount);
    uint buyTokens = tokenIndexes[buyToken].getTradingNode().toNonNative(pions); 
    return buyTokens;
  }

  //circulating pions
  function token2TokenGetPionAmount(address sellToken) external view returns(uint rt) {
    return tokenIndexes[sellToken].getTradingNode().getTotalSellActiveAmount();
  }

  //circulating tokens
  function token2TokenGetTokenAmount(address buyToken) external view returns(uint rt) {
    return tokenIndexes[buyToken].getTradingNode().getTotalBuyActiveAmount();
  }

  function getCurrentIndex(address forToken) external view returns(uint rt) {
    return tokenIndexes[forToken].getCurrentIndex();
  }

  function extraFunction(address tokenAddress, address[] memory inAddress, uint[] memory inUint) public returns(bool rt) {
    tokenIndexes[tokenAddress].extraFunction(inAddress, inUint);
    return true;
  }

}


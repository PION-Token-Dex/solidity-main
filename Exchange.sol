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

contract Exchange {

  address private pionAddress;
  address private activeIndexesAddress;
  ActiveIndexes private null_activeIndexes;

  mapping(address => ActiveIndexes) private tokenIndexes;

  function setPionAddress(address pionAddress_) external {
    pionAddress = pionAddress_;
  }

  function addToken(address tokenAddress) private {
    tokenIndexes[tokenAddress] = ActiveIndexes(activeIndexesAddress);
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external {
    if (tokenIndexes[forToken] == null_activeIndexes) {
      addToken(forToken);
    }
    tokenIndexes[forToken].buy(userAddress, priceIndex, amount);
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) external {
    if (tokenIndexes[forToken] == null_activeIndexes) {
      addToken(forToken);
    }
    tokenIndexes[forToken].sell(userAddress, priceIndex, amount);
  }

  function cancelOrders(address forToken, address userAddress, uint priceIndex) external {
    tokenIndexes[forToken].cancelAt(userAddress, priceIndex);
  }

  function withdrawAll(address forToken, address userAddress, uint priceIndex) external {
    tokenIndexes[forToken].withdrawAll(userAddress, priceIndex);
  }

  function getTradeData(address forToken, uint tradePlaces) public view returns(uint[] memory rt) {
    return tokenIndexes[forToken].getTradeData(tradePlaces);
  }

  function getWithdrawBuyData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    return tokenIndexes[forToken].getWithdrawAmountBuy(userAddress, priceIndex);
  }

  function getWithdrawSellData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    return tokenIndexes[forToken].getWithdrawAmountSell(userAddress, priceIndex);
  }
  //--------------------------------

  function token2TokenCalculate(address sellToken, address buyToken, uint amount) public view returns(uint rt) {
    uint pions = tokenIndexes[sellToken].currentToPionConversion(amount);
    uint buyTokens = tokenIndexes[buyToken].currentToTokenConversion(pions);
    return buyTokens;
  }

  //circulating pions
  function token2TokenGetPionAmount(address sellToken) public view returns(uint rt) {
    return tokenIndexes[sellToken].getCurrentSellAmount();
  }

  //circulating tokens
  function token2TokenGetTokenAmount(address buyToken) public view returns(uint rt) {
    return tokenIndexes[buyToken].getCurrentBuyAmount();
  }

}

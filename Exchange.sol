// SPDX-License-Identifier: MIT

pragma solidity ^ 0.7 .0;

abstract contract ActiveIndexes {
  function buy(address tokenAddress, address userAddress, uint priceIndex, uint amount) external virtual returns(bool rt);

  function sell(address tokenAddress, address userAddress, uint priceIndex, uint amount) external virtual returns(bool rt);

  function cancelAt(address tokenAddress, address userAddress, uint priceIndex) external virtual returns(bool rt);

  function withdrawAll(address tokenAddress, address userAddress, uint priceIndex) external virtual returns(bool rt);

  function withdrawBuy(address tokenAddress, address userAddress, uint priceIndex, uint amount) external virtual returns(bool rt);

  function withdrawSell(address tokenAddress, address userAddress, uint priceIndex, uint amount) external virtual returns(bool rt);

  function getTradeData(address tokenAddress, uint tradePlaces) external virtual view returns(uint[] memory rt);

  function getWithdrawAmountBuy(address tokenAddress, address usrAddress, uint priceIndex) external virtual view returns(uint rt);

  function getWithdrawAmountSell(address tokenAddress, address usrAddress, uint priceIndex) external virtual view returns(uint rt);

  function getAmountBuy(address tokenAddress, address usrAddress, uint priceIndex) external virtual view returns(uint rt);

  function getAmountSell(address tokenAddress, address usrAddress, uint priceIndex) external virtual view returns(uint rt);
}

abstract contract TokenTransfer {
  function allowance(address owner, address spender) virtual external view returns(uint256);

  function transferFrom(address sender, address recipient, uint256 amount) virtual external returns(bool);

  function balanceOf(address account) virtual external view returns(uint256);

  function transfer(address recipient, uint256 amount) virtual external returns(bool);
}

contract Exchange {

  ActiveIndexes private tokenIndexes;

  address private pionAdress;
  address private activeIndexesAddress;

  constructor(address pionAdress_) {
    pionAdress = pionAdress_;
  }

  function checkCall() private view {
    require(msg.sender == pionAdress || msg.sender == address(this));
  }

  function getExchangeAddress() external view returns(address rt) {
    checkCall();
    return address(this);
  }

  function setActiveIndexAddress(address activeIndexAddress_) external {
    checkCall();
    activeIndexesAddress = activeIndexAddress_;
    tokenIndexes = ActiveIndexes(activeIndexAddress_);
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    checkCall();
    require(depositTokenToExchange(forToken, userAddress, amount));
    require(tokenIndexes.buy(forToken, userAddress, priceIndex, amount));
    require(withdrawAll(forToken, userAddress, priceIndex));
    return true;
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    checkCall();
    require(depositTokenToExchange(pionAdress, userAddress, amount));
    require(tokenIndexes.sell(forToken, userAddress, priceIndex, amount));
    require(withdrawAll(forToken, userAddress, priceIndex));
    return true;
  }

  function cancelOrders(address forToken, address userAddress, uint priceIndex) external returns(bool rt) {
    checkCall();
    require(tokenIndexes.cancelAt(forToken, userAddress, priceIndex));
    require(withdrawAll(forToken, userAddress, priceIndex));
    return true;
  }

  function withdrawAll(address forToken, address userAddress, uint priceIndex) public returns(bool rt) {
    checkCall();

    uint withdrawSellData = getWithdrawSellData(forToken, userAddress, priceIndex);
    uint withdrawBuyData = getWithdrawBuyData(forToken, userAddress, priceIndex);

    if (withdrawSellData > 0) {
      require(sendTokenToUser(forToken, userAddress, withdrawSellData));
    }

    if (withdrawBuyData > 0) {
      require(sendTokenToUser(pionAdress, userAddress, withdrawBuyData));
    }

    if (withdrawSellData > 0 || withdrawBuyData > 0) {
      require(tokenIndexes.withdrawAll(forToken, userAddress, priceIndex));
    }
    return true;
  }

  function withdrawBuy(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    checkCall();
    require(tokenIndexes.withdrawBuy(forToken, userAddress, priceIndex, amount));
    return true;
  }

  function withdrawSell(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    checkCall();
    require(tokenIndexes.withdrawSell(forToken, userAddress, priceIndex, amount));
    return true;
  }

  function getTradeData(address forToken, uint tradePlaces) external view returns(uint[] memory rt) {
    checkCall();
    return tokenIndexes.getTradeData(forToken, tradePlaces);
  }

  function getWithdrawBuyData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    checkCall();
    return tokenIndexes.getWithdrawAmountBuy(forToken, userAddress, priceIndex);
  }

  function getWithdrawSellData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    checkCall();
    return tokenIndexes.getWithdrawAmountSell(forToken, userAddress, priceIndex);
  }

  function getBuyData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    checkCall();
    return tokenIndexes.getAmountBuy(forToken, userAddress, priceIndex);
  }

  function getSellData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    checkCall();
    return tokenIndexes.getAmountSell(forToken, userAddress, priceIndex);
  }

  //--------------------------------

  function depositTokenToExchange(address tokenAddress, address userAddress, uint amount) private returns(bool rt) {
    TokenTransfer tok = TokenTransfer(tokenAddress);
    require(tok.allowance(userAddress, address(this)) >= amount);
    tok.transferFrom(userAddress, address(this), amount);
    return true;
  }

  function sendTokenToUser(address tokenAddress, address userAddress, uint amount) private returns(bool rt) {
    TokenTransfer tok = TokenTransfer(tokenAddress);
    require(tok.balanceOf(address(this)) >= amount);
    tok.transfer(userAddress, amount);
    return true;
  }

}

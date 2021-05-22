// SPDX-License-Identifier: MIT

import "contracts/main/Ownable.sol";
import "contracts/main/Exchange.sol";

pragma solidity ^ 0.7 .0;

contract Exchanges is Ownable {

  mapping(uint => Exchange) private echangeVersion;
  mapping(uint => bool) private allowedExchangeVersions;
  uint public currentExchangeVersion = 0;
  address public pionAdress;

  constructor(address pionAdress_) {
    pionAdress = pionAdress_;
  }

  //----START Used by main contract--------

  function isExchangeVersionAllowed(uint exchangeVersion) external view returns(bool rt) {
    return allowedExchangeVersions[exchangeVersion];
  }

  function getCurrentExchangeVersion() external view returns(uint rt) {
    return currentExchangeVersion;
  }

  function depositTokenToExchange(address tokenAddress, address userAddress, uint amount) public returns(bool rt) {
    requirePionOrThis();
    TokenTransfer tok = TokenTransfer(tokenAddress);
    require(tok.allowance(userAddress, pionAdress) >= amount);
    tok.transferFrom(userAddress, pionAdress, amount);
    return true;
  }

  function sendTokenToUser(address tokenAddress, address userAddress, uint amount) public returns(bool rt) {
    requirePionOrThis();
    TokenTransfer tok = TokenTransfer(tokenAddress);
    require(tok.balanceOf(userAddress) >= amount);
    tok.transfer(userAddress, amount);
    return true;
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount, uint atExchangeVersion) external returns(bool rt) {
    requireExchange(atExchangeVersion);

    require(depositTokenToExchange(forToken, userAddress, amount));
    require(echangeVersion[atExchangeVersion].buyPion(forToken, userAddress, priceIndex, amount));
    registerIndexAdd(forToken, userAddress, priceIndex, atExchangeVersion);
    require(withdrawAllAtIndex(forToken, userAddress, priceIndex, atExchangeVersion));
    registerIndexWithdraw(userAddress, atExchangeVersion);

    return true;
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount, uint atExchangeVersion) external returns(bool rt) {
    requireExchange(atExchangeVersion);

    require(depositTokenToExchange(pionAdress, userAddress, amount));
    require(echangeVersion[atExchangeVersion].sellPion(forToken, userAddress, priceIndex, amount));
    registerIndexAdd(forToken, userAddress, priceIndex, atExchangeVersion);
    registerIndexWithdraw(userAddress, atExchangeVersion);
    return true;
  }

  function cancelAllTradesAtIndex(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) external returns(bool rt) {
    requirePionOrThis();
    require(echangeVersion[atExchangeVersion].cancelOrders(forToken, userAddress, priceIndex));
    require(withdrawAllAtIndex(forToken, userAddress, priceIndex, atExchangeVersion));
    require(echangeVersion[atExchangeVersion].moveLastActiveIndex(userAddress));
    return true;
  }

  //todo check which one is a pion and which one is a token
  function withdrawAllAtIndex(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) public returns(bool rt) {
    requirePionOrThis();
    uint withdrawSellData = echangeVersion[atExchangeVersion].getWithdrawSellData(forToken, userAddress, priceIndex);
    uint withdrawBuyData = echangeVersion[atExchangeVersion].getWithdrawBuyData(forToken, userAddress, priceIndex);
    require(echangeVersion[atExchangeVersion].withdrawAll(forToken, userAddress, priceIndex));

    if (withdrawSellData > 0) {
      require(sendTokenToUser(forToken, userAddress, withdrawSellData));
    }

    if (withdrawBuyData > 0) {
      require(sendTokenToUser(pionAdress, userAddress, withdrawBuyData));
    }

    registerIndexWithdraw(userAddress, atExchangeVersion);

    return true;
  }

  function token2TokenSwap(address sellToken, address buyToken, address userAddress, uint atExchangeVersion, uint amount) external returns(bool rt) {
    requireExchange(atExchangeVersion);

    uint tokensReturned = echangeVersion[atExchangeVersion].token2TokenCalculate(sellToken, buyToken, amount);
    uint pionAmount = echangeVersion[atExchangeVersion].token2TokenGetPionAmount(sellToken);
    uint buyTokenAmount = echangeVersion[atExchangeVersion].token2TokenGetTokenAmount(buyToken);

    require(buyTokenAmount >= tokensReturned);
    require(depositTokenToExchange(sellToken, userAddress, amount));

    uint sellTokenIndex = echangeVersion[atExchangeVersion].getCurrentIndex(sellToken);
    require(echangeVersion[atExchangeVersion].buyPion(sellToken, userAddress, sellTokenIndex, amount));

    uint buyTokenIndex = echangeVersion[atExchangeVersion].getCurrentIndex(buyToken);
    require(echangeVersion[atExchangeVersion].sellPion(buyToken, userAddress, buyTokenIndex, pionAmount));

    require(withdrawAllAtIndex(buyToken, userAddress, buyTokenIndex, atExchangeVersion));

    registerIndexWithdraw(userAddress, atExchangeVersion);

    return true;
  }

  function extraFunction(uint atExchangeVersion, address tokenAddress, address[] memory inAddress, uint[] memory inUint) external returns(bool rt) {
    requirePionOrThis();
    echangeVersion[atExchangeVersion].extraFunction(tokenAddress, inAddress, inUint);
    return true;
  }

  function getTokenPriceIndexes(uint atExchangeVersion, address userAddress, address tokenAddress, uint maxIndexes) external view returns(uint[] memory rt) {
    requirePionOrThis();
    return echangeVersion[atExchangeVersion].getTokenPriceIndexes(userAddress, tokenAddress, maxIndexes);
  }

  //----END Used by main contract--------

  function setNewExchange() public onlyOwner returns(bool rt) {
    ++currentExchangeVersion;
    echangeVersion[currentExchangeVersion] = new Exchange();
    allowedExchangeVersions[currentExchangeVersion] = true;
    return true;
  }

  function switchAllowExchangeVersion(uint exchangeVersion) public onlyOwner returns(bool rt) {
    allowedExchangeVersions[exchangeVersion] = !allowedExchangeVersions[exchangeVersion];
    return true;
  }

  function requireExchange(uint atExchangeVersion) private view {
    requirePionOrThis();
    require(atExchangeVersion <= currentExchangeVersion && atExchangeVersion > 0);
    require(allowedExchangeVersions[atExchangeVersion]);
  }
  
  function requirePionOrThis() private view {
    require(msg.sender == pionAdress || msg.sender == address(this));
  }

  function registerIndexAdd(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) private {
    require(echangeVersion[atExchangeVersion].addIndex(userAddress, forToken, priceIndex));
    require(echangeVersion[atExchangeVersion].addIndex(userAddress, pionAdress, priceIndex));
  }

  function registerIndexWithdraw(address userAddress, uint atExchangeVersion) private {
    require(echangeVersion[atExchangeVersion].moveLastActiveIndex(userAddress));
  }

}

// SPDX-License-Identifier: MIT


pragma solidity ^ 0.7 .0;

contract IndexManagement {
//   struct Indexes {
//     mapping(uint => address) tokenMap; //id, tokenAddress
//     mapping(uint => uint) priceIndex; //id, priceIndex
//     uint lastId;
//     uint lastActiveIdBottom;
//   }

//   mapping(address => Indexes) internal userIndexes; //user address, indexes

//   function addIndex_(address userAddress, address tokenAddress, uint priceIndex) internal returns(bool rt) {
//     uint lastId = userIndexes[userAddress].lastId;
//     ++lastId;
//     userIndexes[userAddress].lastId = lastId;
//     userIndexes[userAddress].tokenMap[lastId] = tokenAddress;
//     userIndexes[userAddress].priceIndex[lastId] = priceIndex;
//     return true;
//   }

//   function moveLastActiveIndex(address userAddress, uint toIndex) internal {
//     userIndexes[userAddress].lastActiveIdBottom = toIndex;
//   }
  


//   function getTokenPriceIndexes(address userAddress, address tokenAddress, uint maxIndexes) external view returns(uint[] memory rt) {
//     uint[] memory ret = new uint[](maxIndexes);
//     uint from = userIndexes[userAddress].lastActiveIdBottom;
//     uint to = userIndexes[userAddress].lastId;
//     uint t = 0;
//     uint cnt = 0;
//     for (; from <= to; from++) {
//       if (cnt == 10000) break;
//       if (userIndexes[userAddress].tokenMap[from] == tokenAddress) {
//         ret[t] = userIndexes[userAddress].priceIndex[from];
//         ++t;
//         if (t == maxIndexes) break;
//       }
//       ++cnt;
//     }
//     return ret;
//   }

}


abstract contract ActiveIndexes {
function buy(address tokenAddress, address userAddress, uint priceIndex, uint amount) external virtual returns(bool rt);
function sell(address tokenAddress, address userAddress, uint priceIndex, uint amount) external virtual returns(bool rt);
function cancelAt(address tokenAddress, address userAddress, uint priceIndex) external virtual returns(bool rt);
function withdrawAll(address tokenAddress, address userAddress, uint priceIndex) external virtual returns(bool rt);
function withdrawBuy(address tokenAddress, address userAddress, uint priceIndex, uint amount) external virtual returns(bool rt);
function withdrawSell(address tokenAddress, address userAddress, uint priceIndex, uint amount) external virtual returns(bool rt);
function getTradeData(address tokenAddress, uint tradePlaces) external virtual view returns(uint[] memory rt);
function getTradingNode(address tokenAddress, uint priceIndex) external virtual view returns(TradingNode rt);
function getTradingNode(address tokenAddress) external virtual view returns(TradingNode rt);
function getCurrentIndex(address tokenAddress) external virtual view returns(uint rt);
function extraFunction(address tokenAddress, address[] memory inAddress, uint[] memory inUint) public virtual returns(bool rt);
function getWithdrawAmountBuy(address tokenAddress, uint priceIndex, address usrAddress) public virtual view returns(uint rt);
function getWithdrawAmountSell(address tokenAddress, uint priceIndex, address usrAddress) public virtual view returns(uint rt);
}

abstract contract TradingNode {
  function getWithdrawAmountBuy(address usrAddress) external virtual view returns(uint rt);

  function getWithdrawAmountSell(address usrAddress) external virtual view returns(uint rt);

  function toNative(uint nonNativeAmount) public virtual view returns(uint rt);

  function toNonNative(uint nonNativeAmount) public virtual view returns(uint rt);

  function getTotalBuyActiveAmount() external virtual view returns(uint rt);

  function getTotalSellActiveAmount() external virtual view returns(uint rt);
}

contract Exchange is IndexManagement {
    
 
    

  ActiveIndexes private tokenIndexes;

  address private pionAdress = address(12345);
  address private activeIndexesAddress;

//   constructor(address exchangesAddress_) {
//     exchangesAddress = exchangesAddress_;
//   }

  function checkCall() private view {
    //require(msg.sender == exchangesAddress || msg.sender == address(this));
  }

  function getExchangeAddress() public view returns(address rt) {
    return address(this);
  }

  function setActiveIndexAddress(address activeIndexAddress_) external {
    checkCall();
    activeIndexesAddress = activeIndexAddress_;
    tokenIndexes = ActiveIndexes(activeIndexAddress_);
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    //    require(depositTokenToExchange(forToken, userAddress, amount));
    // checkCall();
    require(tokenIndexes.buy(forToken, userAddress, priceIndex, amount));
    withdrawAll_(forToken, userAddress, priceIndex);
    return true;
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    checkCall();
    require(tokenIndexes.sell(forToken, userAddress, priceIndex, amount));
    return true;
  }

  function cancelOrders(address forToken, address userAddress, uint priceIndex) external returns(bool rt) {
    checkCall();
    tokenIndexes.cancelAt(forToken, userAddress, priceIndex);
    return true;
  }

  function withdrawAll_(address forToken, address userAddress, uint priceIndex) public returns(bool rt) {
    // checkCall();
    
    uint withdrawSellData = getWithdrawSellData(forToken, userAddress, priceIndex);
    // uint withdrawBuyData = getWithdrawBuyData(forToken, userAddress, priceIndex);
    
    // if (withdrawSellData > 0) {
    // //   require(sendTokenToUser(forToken, userAddress, withdrawSellData));
    // }

    // if (withdrawBuyData > 0) {
    //   require(sendTokenToUser(pionAdress, userAddress, withdrawBuyData));
    // }

    // tokenIndexes.withdrawAll(forToken, userAddress, priceIndex);
    return true;
  }

  function withdrawBuy(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    checkCall();
    tokenIndexes.withdrawBuy(forToken, userAddress, priceIndex, amount);
    return true;
  }

  function withdrawSell(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    checkCall();
    tokenIndexes.withdrawSell(forToken, userAddress, priceIndex, amount);
    return true;
  }

  function getTradeData(address forToken, uint tradePlaces) external view returns(uint[] memory rt) {
    checkCall();
    return tokenIndexes.getTradeData(forToken, tradePlaces);
  }

  function getWithdrawBuyData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    checkCall();
    if(tokenIndexes.getTradingNode(forToken)==tokenIndexes.getTradingNode(address(0))){return 0;}
    return tokenIndexes.getWithdrawAmountBuy( forToken,  priceIndex,  userAddress);
  }

  function getWithdrawSellData(address forToken, address userAddress, uint priceIndex) public view returns(uint rt) {
    checkCall();
    if(tokenIndexes.getTradingNode(forToken)==tokenIndexes.getTradingNode(address(0))){return 0;}
    return tokenIndexes.getWithdrawAmountSell( forToken,  priceIndex,  userAddress);
  }
  //--------------------------------

  function token2TokenCalculate(address sellToken, address buyToken, uint amount) external view returns(uint rt) {
    checkCall();
    uint pions = tokenIndexes.getTradingNode(sellToken).toNative(amount);
    uint buyTokens = tokenIndexes.getTradingNode(buyToken).toNonNative(pions);
    return buyTokens;
  }

  //circulating pions
  function token2TokenGetPionAmount(address sellToken) external view returns(uint rt) {
    checkCall();
    return tokenIndexes.getTradingNode(sellToken).getTotalSellActiveAmount();
  }

  //circulating tokens
  function token2TokenGetTokenAmount(address buyToken) external view returns(uint rt) {
    checkCall();
    return tokenIndexes.getTradingNode(buyToken).getTotalBuyActiveAmount();
  }

  function getCurrentIndex(address forToken) external view returns(uint rt) {
    checkCall();
    return tokenIndexes.getCurrentIndex(forToken);
  }

  function extraFunction(address forToken, address[] memory inAddress, uint[] memory inUint) public returns(bool rt) {
    checkCall();
    tokenIndexes.extraFunction(forToken, inAddress, inUint);
    return true;
  }

  //--------------------------------START INDEX MANAGEMENT-------------

//   function findNextWithdrawIndex(address userAddress) public view returns(uint rt) {
//     uint ret = userIndexes[userAddress].lastActiveIdBottom;
//     uint to = userIndexes[userAddress].lastId;
//     if(ret==to){return ret;}
//     uint cnt=0;
//     for (; ret < to; ret++) {
//       address forToken = userIndexes[userAddress].tokenMap[ret];
//       uint priceIndex = userIndexes[userAddress].priceIndex[ret];
//       uint withdrawBuyData = getWithdrawBuyData(forToken, userAddress, priceIndex);
//       uint withdrawSellData = getWithdrawSellData(forToken, userAddress, priceIndex);
//       if (withdrawBuyData > 0 || withdrawSellData > 0) {
//         break;
//       }
//       if(cnt==10000){
//           break;
//       }
//       cnt++;
//     }
//     return ret;
//   }

//   function registerIndexAdd(address forToken, address userAddress, uint priceIndex) private {
//     addIndex_(userAddress, forToken, priceIndex);
//     addIndex_(userAddress, pionAdress, priceIndex);
//   }

//   function registerIndexWithdraw(address userAddress) public view returns(uint rt){
//       uint indx = findNextWithdrawIndex(userAddress);
//     //   if(lastActiveIndex!=userIndexes[userAddress].lastActiveIdBottom){
//     // moveLastActiveIndex(userAddress, findNextWithdrawIndex(userAddress));
//     //   }
//     return indx;
//   }


  //--------------------------------END INDEX MANAGEMENT---------------

}

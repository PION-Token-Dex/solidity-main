// SPDX-License-Identifier: MIT
// import "contracts/main/AssetManagement.sol";

pragma solidity ^ 0.7 .0;

contract OrderTracker{
    
    struct Order{
        address userAddress;
        uint priceIndex;
        uint pivot;
    }
    
    uint private pivot = 0;
    uint private lowActivePivot = 0;
    mapping (uint => Order) orderMap;
    
    uint private exchangeVersion;
    address private tokenAddress;
    
  constructor(uint exchangeVersion_, address tokenAddress_) {
        exchangeVersion = exchangeVersion_;
        tokenAddress = tokenAddress_;
  }
    
  function newOrder(uint priceIndex) public returns(bool rt) {
      
      orderMap[pivot] = Order({
          userAddress: msg.sender,
          priceIndex: priceIndex,
          pivot: pivot
      });
      
      ++pivot;
      
      return true;
  }

    function truncateOrders() private{
        uint t=lowActivePivot;
        byte orderType = getOrderType(orderMap[t]);
        while(t<pivot && orderType==0x00){
            orderType = getOrderType(orderMap[t]);
            ++t;
        }
        lowActivePivot = t;
    }


      function getOrderType(Order memory order) private view returns(byte rt) {
          //get exchange by exchangeVersion
          //go to token, activeIndexes, return the type
          return 0x00;
      }

    
    function getActiveOrders() private view returns(uint[] memory rt){
        //todo
    }
    
    function getInactiveOrders() private view returns(uint[] memory rt){
        //todo
    }
    
}

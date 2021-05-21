// SPDX-License-Identifier: MIT



contract IndexManagement{
struct Indexes{
    mapping(uint => address)  tokenMap; //id, tokenAddress
    mapping(uint=>uint)  priceIndex; //id, priceIndex
    uint lastId;
    uint lastActiveIdBottom;
}

mapping(address=>Indexes) private userIndexes;  //user address, indexes

function addIndex(address userAddress, address tokenAddress, uint priceIndex) private {
    uint lastId = userIndexes[userAddress].lastId;
    ++lastId;
    userIndexes[userAddress].lastId = lastId;
    userIndexes[userAddress].tokenMap[lastId] = tokenAddress;
    userIndexes[userAddress].priceIndex[lastId] = priceIndex;
}

function moveLastActiveIndex(address userAddress, uint toIndex) private {
    userIndexes[userAddress].lastActiveIdBottom = toIndex;
}

function getTokenPriceIndexes(address userAddress, uint maxIndexes) private view returns(uint[] memory rt){
    uint[] memory ret = new uint[](maxIndexes);
    uint from = userIndexes[userAddress].lastActiveIdBottom;
    uint to = userIndexes[userAddress].lastId;
    uint t = 0;
    for(;from<=to;from++){
        if(userIndexes[userAddress].tokenMap[from]==userAddress){
            ret[t] = userIndexes[userAddress].priceIndex[from];
            ++t;
            if(t==maxIndexes) break;
        }
    }
    return ret;
}
    
}

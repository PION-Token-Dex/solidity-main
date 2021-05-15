// SPDX-License-Identifier: MIT

pragma solidity ^ 0.7 .0;

contract QA {

  struct Bid {
    address userAddress;
    uint amount;
  }

  mapping(uint => Bid) private statusMap;
  mapping(address => uint) private withdrawnAmount;

  uint private currentId;
  uint private lowestId;
  uint private totalInactive;

  function ask(address userAddress, uint amount) public {
    require(amount > 0, "QA: 451, zero amount");
    require(userAddress != address(0), "QA: 316, address zero");
    statusMap[currentId] = Bid({
      userAddress: userAddress,
      amount: amount
    });
    ++currentId;
  }

  function answer(uint amount) public {
    require(amount > 0, "QA: 713, zero amount");
    uint totalamt = getTotalActiveAmount();

    require(amount <= totalamt, "QA: 195, amount > totalamt");
    require((totalamt - amount) > (totalamt / 100) || totalamt - amount == 0, "QA: 663, dusting");

    if (amount == totalamt) {
      lowestId = currentId;
      totalInactive += amount;
    } else {
      answerSplitter(amount);
    }
  }

  function answerSplitter(uint amt) private {
    uint amount = amt;
    uint addToInactive = 0;
    uint newLowestId = lowestId;
    uint current = statusMap[newLowestId].amount;
    uint y = 0;
    while (amount != 0) {
      require(y < 10000, "QA: 146, big loop");
      if (current > amount) {
        statusMap[newLowestId].amount = amount;
        ask(statusMap[newLowestId].userAddress, current - amount);
        addToInactive += amount;
        amount = 0;
      } else if (current == amount) {
        addToInactive = amount;
        amount = 0;
      } else {
        amount -= current;
        addToInactive += current;
      }
      ++newLowestId;
      current = statusMap[newLowestId].amount;
      ++y;
    }
    totalInactive += addToInactive;
    lowestId = newLowestId;
  }

  function cancelAll(address userAddress) external returns (bool tn){
    require(userAddress != address(0), "QA: 212, address(0)");
    uint active = getTotalUserActiveAmount(userAddress);
    if (active == 0) {
      return false;
    }
    processCancel(userAddress, active);
    return true;
  }

  function processCancel(address userAddress, uint amount) private {
    require(amount > 0, "QA: 156, zero cancel amount");
    require(amount <= getTotalUserActiveAmount(userAddress), "QA: 987, amount greater than active");
    answer(amount);
  }

  function withdrawAll(address userAddress) external {
    require(userAddress != address(0), "QA: 486, address(0)");
    uint inactive = getTotalUserInactiveAmount(userAddress);
    if (inactive > 0) {
      withdraw(userAddress, inactive);
    }
  }

  function withdraw(address userAddress, uint amount) public {
    require(amount > 0, "QA: 183, zero withdraw amount");
    require(amount <= getTotalUserInactiveAmount(userAddress), "QA: 522, amount greater than active");
    uint wamt = withdrawnAmount[userAddress];
    wamt += amount;
    withdrawnAmount[userAddress] = wamt;
    totalInactive -= amount;
  }

  function getTotalActiveAmount() public view returns(uint amt) {
    uint ret = 0;
    uint y = lowestId;
    while (y < currentId) {
      require(y < 10000, "QA: 934, big loop");
      ret += statusMap[y].amount;
      ++y;
    }
    return ret;
  }

  function getTotalUserActiveAmount(address userAddress) private view returns(uint amt) {
    uint ret = 0;
    uint y = lowestId;
    while (y < currentId) {
      require(y < 10000, "QA: 389, big loop");
      if (statusMap[y].userAddress == userAddress) {
        ret += statusMap[y].amount;
      }
      ++y;
    }
    return ret;
  }

  function getTotalUserInactiveAmount(address userAddress) public view returns(uint amtn) {
    uint ret = 0;
    uint trackAmt = totalInactive;
    uint t = 0;
    while (t < lowestId) {
      require(t < 10000, "QA: 484, big loop");
      if (userAddress == statusMap[t].userAddress) {
        uint amt = statusMap[t].amount;
        if (amt > trackAmt) {
          ret += trackAmt;
          break;
        }
        ret += amt;
        trackAmt -= amt;
      }
      ++t;
    }

    return ret;
  }

  function getQAStatus() external view returns(byte amt) {
    uint inactive = getTotalInactiveAmount();
    uint active = getTotalActiveAmount();
    return (byte)(active == 0 && inactive == 0 ? 0 : active != 0 ? 1 : 2);
  }

  function getTotalInactiveAmount() private view returns(uint amt) {
    return totalInactive;
  }

}

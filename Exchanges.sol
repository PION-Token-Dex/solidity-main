import "contracts/main/Ownable.sol";
import "contracts/main/Exchange.sol";


contract Exchanges is Ownable {

  mapping(uint => Exchange) private echangeVersion;
  mapping(uint => bool) private allowedExchangeVersions;
  uint public currentExchangeVersion = 0;
  address public pionAdress;

  constructor(address pionAdress_) {
    pionAdress = pionAdress_;
  }

  function getExchange(uint atExchangeVersion) external view returns(Exchange) {
    require(msg.sender == pionAdress, "ES: 95, not PION address");
    return echangeVersion[atExchangeVersion];
  }

  function isExchangeVersionAllowed(uint exchangeVersion) public view returns(bool rt) {
    return allowedExchangeVersions[exchangeVersion];
  }

  //only allowed exchanges can make the buy/sell
  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    bool bought = buyPion(forToken, userAddress, priceIndex, amount, currentExchangeVersion);
    require(bought, "ES: 618, not bought");
    return true;
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount, uint atExchangeVersion) public returns(bool rt) {
    require(msg.sender == pionAdress, "ES: 944, not PION address");
    require(atExchangeVersion <= currentExchangeVersion && atExchangeVersion > 0, "ES 264, no exchangeVersion");
    require(allowedExchangeVersions[atExchangeVersion], "ES: 954, exchange not allowed");

    bool deposited = depositTokenToExchange(forToken, userAddress, amount);
    require(deposited, "ES 508, not deposited");
    bool bought = echangeVersion[atExchangeVersion].buyPion(forToken, userAddress, priceIndex, amount);
    require(bought, "ES 491, not bought");

    bool withdrawn = withdrawAllAtIndex(forToken, userAddress, priceIndex, atExchangeVersion);
    require(withdrawn, "ES 746, not withdrawn");

    //TODO deposit index management!
    return true;
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount) external returns(bool rt) {
    bool sold = sellPion(forToken, userAddress, priceIndex, amount, currentExchangeVersion);
    require(sold, "ES 722, not sold");
    return true;
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount, uint atExchangeVersion) public returns(bool rt) {
    require(msg.sender == pionAdress, "ES: 813, not PION address");
    require(atExchangeVersion <= currentExchangeVersion && atExchangeVersion > 0, "ES 976, no exchangeVersion");
    require(allowedExchangeVersions[atExchangeVersion], "ES: 414, exchange not allowed");

    bool deposited = depositTokenToExchange(pionAdress, userAddress, amount);
    require(deposited, "ES 746, not deposited");
    bool sold = echangeVersion[atExchangeVersion].sellPion(forToken, userAddress, priceIndex, amount);
    require(sold, "ES 572, not sold");

    bool withdrawn = withdrawAllAtIndex(forToken, userAddress, priceIndex, atExchangeVersion);
    require(withdrawn, "ES 257, not withdrawn");
    return true;
  }

  function cancelAllTradesAtIndex(address forToken, address userAddress, uint priceIndex) external returns(bool rt) {
    require(msg.sender == pionAdress, "ES: 972, not PION address");
    require(allowedExchangeVersions[currentExchangeVersion], "ES: 991, exchange not allowed");

    bool canceled = cancelAllTradesAtIndex(forToken, userAddress, priceIndex, currentExchangeVersion);
    require(canceled, "ES 113, not canceled");
    //TODO deposit index management!
    return true;
  }

  function cancelAllTradesAtIndex(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) public returns(bool rt) {
    require(msg.sender == pionAdress, "ES: 611, not PION address");

    bool canceled = echangeVersion[atExchangeVersion].cancelOrders(forToken, userAddress, priceIndex);
    require(canceled, "ES 113, not canceled");

    bool withdrawn = withdrawAllAtIndex(forToken, userAddress, priceIndex, atExchangeVersion);
    require(withdrawn, "ES 982, not withdrawn");
    //todo deposit index management!
    return true;
  }

  //todo check which one is a pion and which one is a token
  function withdrawAllAtIndex(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) public returns(bool rt) {
    require(msg.sender == pionAdress, "ES: 267, not PION address");

    uint withdrawSellData = echangeVersion[atExchangeVersion].getWithdrawSellData(forToken, userAddress, priceIndex);
    uint withdrawBuyData = echangeVersion[atExchangeVersion].getWithdrawBuyData(forToken, userAddress, priceIndex);
    bool withdrawn = echangeVersion[atExchangeVersion].withdrawAll(forToken, userAddress, priceIndex);
    require(withdrawn, "ES 997, not withdrawn");

    if (withdrawSellData > 0) {
      bool sent = sendTokenToUser(forToken, userAddress, withdrawSellData);
      require(sent, "ES 271, not sent");

    }

    if (withdrawBuyData > 0) {
      bool sent = sendTokenToUser(pionAdress, userAddress, withdrawBuyData);
      require(sent, "ES 991, not sent");
    }
    //TODO deposit index management!
    return true;
  }

  function token2TokenSwap(address sellToken, address buyToken, address userAddress, uint atExchangeVersion, uint amount) external returns(bool rt) {
    require(msg.sender == pionAdress, "ES: 690, not PION address");
    require(atExchangeVersion <= currentExchangeVersion && atExchangeVersion > 0, "ES 231, no exchangeVersion");
    require(allowedExchangeVersions[atExchangeVersion], "ES: 995, exchange not allowed");

    uint tokensReturned = echangeVersion[atExchangeVersion].token2TokenCalculate(sellToken, buyToken, amount);
    uint pionAmount = echangeVersion[atExchangeVersion].token2TokenGetPionAmount(sellToken);
    uint buyTokenAmount = echangeVersion[atExchangeVersion].token2TokenGetTokenAmount(buyToken);

    require(buyTokenAmount >= tokensReturned, "ES: 247, not enough tokens");
    bool deposited = depositTokenToExchange(sellToken, userAddress, amount);
    require(deposited, "ES 766, not deposited");

    uint sellTokenIndex = echangeVersion[atExchangeVersion].getCurrentIndex(sellToken);
    bool bought = echangeVersion[atExchangeVersion].buyPion(sellToken, userAddress, sellTokenIndex, amount);
    require(bought, "ES 265, not bought");

    uint buyTokenIndex = echangeVersion[atExchangeVersion].getCurrentIndex(buyToken);
    bool sold = echangeVersion[atExchangeVersion].sellPion(buyToken, userAddress, buyTokenIndex, pionAmount);
    require(sold, "ES 157, not sold");

    bool withdrawn = withdrawAllAtIndex(buyToken, userAddress, buyTokenIndex, atExchangeVersion);
    require(withdrawn, "ES 665, not withdrawn");
    return true;
  }

  function setNewExchange() public onlyOwner returns(bool rt) {
    ++currentExchangeVersion;
    echangeVersion[currentExchangeVersion] = new Exchange();
    allowedExchangeVersions[currentExchangeVersion] = true;
    return true;
  }

  //we want to be able to use multiple exchanges
  function switchAllowExchangeVersion(uint exchangeVersion) public onlyOwner returns(bool rt) {
    allowedExchangeVersions[exchangeVersion] = !allowedExchangeVersions[exchangeVersion];
    return true;
  }

  function depositTokenToExchange(address tokenAddress, address userAddress, uint amount) private returns(bool rt) {
    TokenTransfer tok = TokenTransfer(tokenAddress);
    require(tok.allowance(userAddress, pionAdress) >= amount, "ES: 828, large amount");
    tok.transferFrom(userAddress, pionAdress, amount);
    return true;
  }

  function sendTokenToUser(address tokenAddress, address userAddress, uint amount) private returns(bool rt) {
    TokenTransfer tok = TokenTransfer(tokenAddress);
    require(tok.balanceOf(userAddress) >= amount, "ES: 573, large amount");
    tok.transfer(userAddress, amount);
    return true;
  }

  function extraFunction(uint atExchangeVersion, address tokenAddress, address[] memory inAddress, uint[] memory inUint) private returns(bool rt) {
    echangeVersion[atExchangeVersion].extraFunction(tokenAddress, inAddress, inUint);
    return true;
  }

}

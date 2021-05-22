// SPDX-License-Identifier: MIT
import "contracts/main/Ownable.sol";

pragma solidity ^ 0.7 .0;

abstract contract NewToken {
  function owner() public view virtual returns(address);
}

contract Registration is Ownable {

  //User can register a token using the owner account, if and only if they can make a call to "owner()" function.
  //Otherwise, they have to contact the exchange owner for a listing.

  mapping(address => string) private tokenName;
  mapping(address => string) private tokenSymbol;
  mapping(address => string) private logoURL;
  mapping(address => string) private webURL;
  mapping(address => string) private socialURL;
  mapping(address => string) private whitePaperURL;
  mapping(address => string) private description;
  mapping(address => string) private extra1;
  mapping(address => string) private extra2;
  mapping(address => string) private extra3;
  mapping(address => uint) private flag1; //for internal use only, 10000 is a block

  mapping(address => uint) private addressToId;
  mapping(uint => address) private IdToAddress;
  uint private tokenId;
  address private pionAddress;

  constructor(address pionAddress_) {
    pionAddress = pionAddress_;
  }

  function addTokenAddress(address tokenAddress) external returns(bool) {
    require(addressToId[tokenAddress] == 0);
    ++tokenId;
    addressToId[tokenAddress] = tokenId;
    IdToAddress[tokenId] = tokenAddress;
    return true;
  }

  function getAddressId(address tokenAddress) external view returns(uint) {
    return addressToId[tokenAddress];
  }

  function getIdAddress(uint id) external view returns(address) {
    return IdToAddress[id];
  }

  function getId() external view returns(uint) {
    return tokenId;
  }

  function setFlag1(address tokenAddress, uint flag) external onlyOwner returns(bool) {
    flag1[tokenAddress] = flag;
    return true;
  }

  function changeTokenName(address tokenAddress, string memory tokenName_) external returns(bool) {
    requirePionOrFlag();
    tokenName[tokenAddress] = tokenName_;
    return true;
  }

  function changeTokenSymbol(address tokenAddress, string memory tokenSymbol_) external returns(bool) {
    requirePionOrFlag();
    tokenSymbol[tokenAddress] = tokenSymbol_;
    return true;
  }

  function changeTokenLogo(address tokenAddress, string memory logoURL_) external returns(bool) {
    requirePionOrFlag();
    logoURL[tokenAddress] = logoURL_;
    return true;
  }

  function changeTokenWeb(address tokenAddress, string memory webURL_) external returns(bool) {
    requirePionOrFlag();
    webURL[tokenAddress] = webURL_;
    return true;
  }

  function changeTokenSocial(address tokenAddress, string memory socialURL_) external returns(bool) {
    requirePionOrFlag();
    socialURL[tokenAddress] = socialURL_;
    return true;
  }

  function changeTokenWhitepaper(address tokenAddress, string memory whitePaperURL_) external returns(bool) {
    requirePionOrFlag();
    whitePaperURL[tokenAddress] = whitePaperURL_;
    return true;
  }

  function changeTokenDescription(address tokenAddress, string memory description_) external returns(bool) {
    requirePionOrFlag();
    description[tokenAddress] = description_;
    return true;
  }

  function changeExtra1(address tokenAddress, string memory extra) external returns(bool) {
    requirePionOrFlag();
    extra1[tokenAddress] = extra;
    return true;
  }

  function changeExtra2(address tokenAddress, string memory extra) external returns(bool) {
    requirePionOrFlag();
    extra2[tokenAddress] = extra;
    return true;
  }

  function changeExtra3(address tokenAddress, string memory extra) external returns(bool) {
    requirePionOrFlag();
    extra3[tokenAddress] = extra;
    return true;
  }

  function registerToken(address tokenAddress, string memory tokenName_, string memory tokenSymbol_, string memory logoURL_, string memory webURL_,
    string memory socialURL_, string memory whitePaperURL_, string memory description_) external returns(bool) {
    requirePionOrFlag();
    tokenName[tokenAddress] = tokenName_;
    tokenSymbol[tokenAddress] = tokenSymbol_;
    logoURL[tokenAddress] = logoURL_;
    webURL[tokenAddress] = webURL_;
    socialURL[tokenAddress] = socialURL_;
    whitePaperURL[tokenAddress] = whitePaperURL_;
    description[tokenAddress] = description_;
    return true;
  }

  function getContractOwner(address tokenAddress) public view returns(address rt) {
    NewToken newToken = NewToken(tokenAddress);
    return newToken.owner();
  }

  function requirePionOrFlag() private view {
    require(flag1[msg.sender] != 10000 && msg.sender == pionAddress);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./libraries/NovaTokenAccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract NovaToken is ERC721A, NovaTokenAccessControl, Pausable, ReentrancyGuard, EIP712 {
    bytes32 public whitelistMerkleRoot;

    uint public immutable maxSupply;
    uint public whitelistPrice;
    uint public publicPrice;    
    
    // 이부분은 추후 배포전에 정책을 정해서 수정해야함
    uint public immutable whitelistSaleBlocknumber;
    uint public immutable whitelistSaleMaxSupply;
    uint public immutable publicSaleBlocknumber;
    uint public immutable maxUnitPerTx = 2;

    bytes32 private constant _SET_WHITELIST_TYPEHASH = keccak256("SetWhitelist(address admin,address user)");

    // =================================
    // EVENT
    // =================================
    event WhitelistRegistered(address indexed user);
    event MintTeamSupply(address indexed to, uint256 startTokenId, uint256 endTokenId, uint when);
    event WhitelistSale(address indexed to, uint256 startTokenId, uint256 endTokenId, uint when);
    event PublicSale(address indexed to, uint256 startTokenId, uint256 endTokenId, uint when);
    
    // 생성자에서는 presaleMaxSupply는 초기값설정을 따로 하진 않는지?
    constructor(uint _maxSupply, uint _whitelistPrice, uint _publicPrice, uint _whitelistSaleBlocknumber, uint _publicSaleBlocknumber, uint _whitelistSaleMaxSupply) ERC721A("NovaToken", "NovaNFT") EIP712("NovaToken", "1") {
        maxSupply = _maxSupply;
        whitelistPrice = _whitelistPrice;
        publicPrice = _publicPrice;
        whitelistSaleBlocknumber = _whitelistSaleBlocknumber;
        publicSaleBlocknumber = _publicSaleBlocknumber;
        whitelistSaleMaxSupply = _whitelistSaleMaxSupply;
    }
    
    // =================================
    // MODIFIERS
    // =================================

    modifier mintMaxSupply(uint _maxSupply, uint _unit) {
        require(_nextTokenId() + _unit <= _maxSupply, "Max supply exceeded");
        _;
    }

    modifier mintPriceCheck(uint _price) {
        require(msg.value >= _price, "Insufficient ETH");
        _;
    }

    modifier afterCheck(uint blockNumber) {
        require(block.number >= blockNumber, "Not yet");
        _;
    }

    modifier periodCheck(uint _startBlockNumber, uint _endBlockNumber) {
        require(block.number >= _startBlockNumber && block.number < _endBlockNumber, "Not yet");
        _;
    }
    
    // =================================
    // PUBLIC FUNCTIONS
    // =================================

    function mintTeamSupply(uint _teamSupply) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_nextTokenId() + _teamSupply <= maxSupply, "Max supply exceeded");
        _safeMint(msg.sender, _teamSupply);
        emit MintTeamSupply(msg.sender, _nextTokenId() - _teamSupply, _nextTokenId() - 1, block.number);
    }
    
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyRole(DEFAULT_ADMIN_ROLE){
        whitelistMerkleRoot=_merkleRoot;
    }

    function whitelistSale(bytes32[] calldata merkleProof, uint _unit)
        public
        payable
        mintPriceCheck(whitelistPrice * _unit)
        periodCheck(whitelistSaleBlocknumber, publicSaleBlocknumber)
        whenNotPaused
        mintMaxSupply(whitelistSaleMaxSupply, _unit)
    {
        require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, toBytes32(msg.sender)) == true, "invalid merkle proof");
        require(_unit <= maxUnitPerTx, "Exceeds max unit per tx");
        
        uint _currentIndex = _nextTokenId();
        _safeMint(msg.sender, _unit);

        emit WhitelistSale(msg.sender, _currentIndex, _currentIndex + _unit - 1, block.number);
    }

    function publicSale(uint _unit)
        public
        payable
        mintPriceCheck(publicPrice * _unit)
        afterCheck(publicSaleBlocknumber)
        whenNotPaused
        mintMaxSupply(maxSupply, _unit)
    {
        require(_unit <= maxUnitPerTx, "Exceeds max unit per tx");
        
        uint _currentIndex = _nextTokenId();
        _safeMint(msg.sender, _unit);
        emit PublicSale(msg.sender, _currentIndex, _currentIndex + _unit - 1, block.number);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}('');
        require(os);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, abi.encodePacked(_toString(tokenId+1), ".json"))) : '';
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // function setWhitelistPrice(uint _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
    //     whitelistPrice = _price;
    // }

    // function setPublicPrice(uint _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
    //     publicPrice = _price;
    // }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, NovaTokenAccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {NovaToken-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    // =================================
    // INTERNAL FUNCTIONS
    // =================================

    function _burn(uint256 tokenId) internal override(ERC721A) {
        super._burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nova9-mint.s3.ap-northeast-1.amazonaws.com/nova/";
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}

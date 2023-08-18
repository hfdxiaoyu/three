// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnuBNBBET is Ownable,ERC721Enumerable{
    constructor() ERC721("LCITY","LCITY") {

    }

    uint[] private  Grande = [1001 , 1002 , 1003, 1004, 1005]; //grade Bronze, Silver, Gold, Diamond, Platinum
    uint private nftId = 1;
    string private baseuri = "https://ipfs.io/ipfs/QmWbKEyNdF6kUu45YXZejfrXZvMk558XKDEH3UtfeazRin"; //nft image address
    mapping(uint => uint) private tokenGrade; //token grade

    mapping(address => uint[]) private adminInfo; //admin
    uint[] private grossAmount = [10000,10000,10000,10000,10000]; //Total amount of various nft types
    uint[] private yield = [0,0,0,0,0]; //The number of nft produced

    event Minter(address indexed from,address indexed to,uint indexed nftid); //生产nft的事件

    function setAdmin(address addr_,uint bnum_,uint snum_,uint gnum_,uint dnum_,uint pnum_) external onlyOwner ismintnum(bnum_,snum_,gnum_,dnum_,pnum_) returns(bool){
        adminInfo[addr_].push(bnum_);
        adminInfo[addr_].push(snum_);
        adminInfo[addr_].push(gnum_);
        adminInfo[addr_].push(dnum_);
        adminInfo[addr_].push(pnum_);
        adminInfo[addr_].push(1); //用来检查是否是admin
        return true;
    }

    //减少某一个管理员的授权数量
    function lessOneAdminAuth(address addr_,uint grande_,uint num_) external onlyOwner verifyGrande(grande_) returns(bool){
        uint _index = grande_ - 1001;
        require(num_ <= adminInfo[addr_][_index],"num_ not exceed auth num");
        adminInfo[addr_][_index] -= num_;
        return true;
    }

    //gets the number of mintable NFTS of admin
    function getAdminMinteNum(address addr_) public view returns(uint[] memory){
        return adminInfo[addr_];
    }

    function forbidAdmin(address addr_) external onlyOwner returns(bool) {
        for (uint i = 0; i < adminInfo[addr_].length; i++) {
            adminInfo[addr_][i] = 0;
        }
        return true;
    } 

    //设置各个等级的最大数量
    function setGrossAmount(uint bnum_,uint snum_,uint gnum_,uint dnum_,uint pnum_) external onlyOwner returns(bool){
        grossAmount[0] = bnum_;
        grossAmount[1] = snum_;
        grossAmount[2] = gnum_;
        grossAmount[3] = dnum_;
        grossAmount[4] = pnum_;
        return true;
    }

    //设置某一个等级的最大数量
    function setOneGrandeGrossAmount(uint grande_,uint amount) external verifyGrande(grande_) onlyOwner returns(bool){
        uint index_ = grande_ - 1001;
        grossAmount[index_] = amount;
        return true;
    }

    //增加某一个等级的最大数量
    function addOneGrandeGrossAmount(uint grande_,uint amount) external verifyGrande(grande_) onlyOwner returns(bool){
        uint index_ = grande_ - 1001;
        grossAmount[index_] += amount;
        return true;
    }

    //减少某一个等级的最大数量
    function lessOneGrandeGrossAmount(uint grande_,uint amount) external verifyGrande(grande_) onlyOwner returns(bool){
        uint index_ = grande_ - 1001;
        grossAmount[index_] -= amount;
        return true;
    }

    //查询可生产的总数
    function getGrossAmount() public view returns(uint[] memory){
        return grossAmount;
    }

    //查询各个等级已生产的总数
    function getYield() public view returns(uint[] memory){
        return yield;
    }

    function _mint1(address addr_,uint grande_) internal ismint verifyGrande(grande_) verifyAdminNum(grande_) verifyGross(grande_) returns(uint){
        require(addr_ != address(0), "address not zero"); 
        address _sender = msg.sender;
        uint _index = grande_ - 1001; //这个可以获取到admin的下标

        for (uint i = 0; i < 5; i++) {
            if (grande_ == Grande[i]) {                        
                tokenGrade[nftId] = Grande[i];
                break;           
            }
        }

        _mint(addr_, nftId);
        if (adminInfo[_sender].length > 0)
            if (adminInfo[_sender][5] > 0 )
                adminInfo[_sender][_index] --;
        yield[_index] ++;
        nftId++;
        emit Minter(_sender,addr_,grande_);
        return nftId - 1;
    }

    function mint(address addr_,uint grande_) external returns(uint){
        return _mint1(addr_,grande_);
    } 

    //Example Query the NFT level
    function getGrande(uint tokneId_) public  view  returns(uint){
        return tokenGrade[tokneId_];
    } 

    //Modify the nft picture
    function setURI(string memory baseuri_) external onlyOwner returns(bool) {
        baseuri = baseuri_;
        return true;
    }

    function _baseURI() internal view override returns(string memory) {
        return baseuri;
    }

    //A way to display a picture
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    //查询一个地址下所有的nftid
    function _owned(address addr_) internal view  returns(uint[] memory){
        uint j = ERC721.balanceOf(addr_);
        uint[] memory _temp = new uint[](j);
        for (uint i = 0; i < j; i++) {
            _temp[i] = ERC721Enumerable.tokenOfOwnerByIndex(addr_, i);
        }
        return _temp;
    }

    //查看一个地址下所有的nftid
    function owned(address addr_) public view returns(uint[] memory){
        return _owned(addr_);
    }

    //Verify that the identity is administrator or owner
    modifier ismint() {
        address _sender = msg.sender;
        require((adminInfo[_sender].length > 0 && (adminInfo[_sender][5]) > 0) || _sender == owner(),"permission denied");
        _;
    }

    modifier ismintnum(uint bnum_,uint snum_,uint gnum_,uint dnum_,uint pnum_){
        require((bnum_ + snum_ + gnum_ + dnum_ + pnum_) > 0,"Total greater equal to 0");
        _;
    }

    modifier verifyAdminNum(uint grande_){
        uint tempindex = grande_ - 1001; //这个可以获取到admin的下标
        address _sender = msg.sender;
        require((_sender == owner()) || (adminInfo[_sender].length > 0 && adminInfo[_sender][tempindex] > 0),"minte is used up");
        _;
    }

    modifier verifyGrande(uint grande_){
        require(grande_ > 1000 && grande_ <1006,"Rank input error");
        _;
    }

    //校验制造数量不能超过最大限制
    modifier verifyGross(uint grande_){
        uint _index = grande_ - 1001;
        require(yield[_index] <= grossAmount[_index],"The quantity available is insufficient");
        _;
    }
}   

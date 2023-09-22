// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SltGame is OwnableUpgradeable {

    //实例化代币接口
    IERC20 public slt;
    IERC20 public usdt;
    
    //常用全局变量
    uint public startTime;   
    address public topAddress; //顶点

    struct UserInfo {
        address invitor; //用户的直接推荐人
        uint refer_n; // 该用户推荐了多少个有效地址
        uint referSltReward; //待领取的直推slt
        uint referSltClaimed; //累计领取的直推slt
        uint buySltReward; // 待领取的认购slt
        uint buySltClaimed; //累计领取的认购slt
        uint UsdtClaimed; //累计领取的奖励USDT
        uint districtID; //属于哪一条普通节点的线（哪个区）,如果该数字不为0，说明是有效用户，已经在网体中了
        uint level; // 用户的等级
    }

    struct NodeInfo { //节点的信息
        bool isSuperNode;
        bool isNormalNode;
        uint subNum; // 下级的数量
    }

    struct TeamInfo { //团队架构信息
        address up1;
        address down1;
        address down2;
        address down3;
        uint lastLevel; //此前的查询中，已经查到了该用户下面的层数
        uint lowNum; //此前的查询中，已经查到这个用户伞下至少到lowNum都是满的（只针对用户所在的区,lowNum本身也是被占用的）
    }

    struct DistrictInfo { //每一条普通节点的线路独有的三叉树结构
        mapping(address => uint)  addressToIndex;
        mapping(uint => address)  indexToAddress;
    }

    struct ClaimInfo { // 领取收益信息： 
        uint types;
        uint amount;
        uint timestamp;
    }

    //全局统计信息
    uint totalUsdtBuy;//用户总入金
    uint totalSuperNode; //超级节点数量
    uint totalNormalNode; //普通节点数量
    uint totalUserNum; // 全局普通用户
    

    mapping(address => bool) public admin; //管理员
    mapping(address => bool) public isBlackList; //是否黑名单
    mapping(address => UserInfo) public userInfo;
    mapping(address => NodeInfo) public nodeInfo;
    mapping(address => TeamInfo) public teamInfo;
    mapping(uint => address) public indexToNormalAddress; //根据三叉树顶点序号找到顶点普通节点的地址  区号 => 地址
    mapping(address => uint) public normalAddressToIndex; //根据普通节点的地址找到三叉树顶点序号，ID从1开始 地址 => 区号
    mapping(uint => DistrictInfo)  district; //数组里面有maping，所以不可以直接public，可以写专门的方法来查询 每个区的映射关系

    // 记录事件
    event Bond(address indexed player, address indexed invitor); // 绑定直推事件


    //修饰方法
    modifier onlyAdmin () { //判断管理员权限
        require(admin[msg.sender] == true, "not admin");
        _;
    }

    modifier checkBlackList () { //判断是否黑名单地址
        require(isBlackList[msg.sender] == false, "black list");
        _;
    }
    
   
   // 设置方法
    function initialize() initializer public {
        __Ownable_init_unchained();
        topAddress = 0x60dAb8F816fdE1ce3939915f3E904Be4E7E017a0; // 设置初始主地址
    }
    
    function setAdmin(address admin_, bool isAdmin_) external onlyOwner { // 设置admin
            admin[admin_] = isAdmin_;
        }
    function setBlackList(address _address, bool isBlackList_) external onlyAdmin { // 设置admin
            isBlackList[_address] = isBlackList_;
        }

    function setTopAddress(address _topAdress) external onlyAdmin { // 设置TopAddress
            topAddress = _topAdress ;
        }

    function setSuperNode(address _nodeAddress) external onlyAdmin { // 设置超级节点
        require(totalSuperNode <= 20, "reach 20 super node");
        userInfo[_nodeAddress].invitor =topAddress;
        teamInfo[_nodeAddress].up1 = topAddress;
        nodeInfo[_nodeAddress].isSuperNode = true;
        totalSuperNode ++;
    }

    function setNormalNode(address _normalNodeAddress, address _superNodeAddress) external onlyAdmin { // 设置普通节点
        require(nodeInfo[_superNodeAddress].isSuperNode = true, "not super node"); // 校验推荐人是否为超级节点
        require(nodeInfo[_superNodeAddress].subNum <= 10, "reach 10 normal node"); // 校验超级节点伞下位置够不够
        userInfo[_normalNodeAddress].invitor =_superNodeAddress;
        teamInfo[_normalNodeAddress].up1 = _superNodeAddress;
        nodeInfo[_normalNodeAddress].isNormalNode = true;
        nodeInfo[_superNodeAddress].subNum ++;
        totalNormalNode ++;
        normalAddressToIndex[_normalNodeAddress] = totalNormalNode; //从地址找到普通节点ID
        indexToNormalAddress[totalNormalNode] = _normalNodeAddress; // 从普通节点的ID找到地址
        userInfo[_normalNodeAddress].districtID = totalNormalNode; // 在userInfo的架构里赋予该地址为有效地址
        district[totalNormalNode].addressToIndex[_normalNodeAddress] = 1; // 初始化该分区
        district[totalNormalNode].indexToAddress[1] = _normalNodeAddress; // 初始化该分区
        
    }

//下面开始业务逻辑
    function bind(address _invitor) external { //绑定直推关系
        require(userInfo[msg.sender].invitor == address(0), "already bond");
        require(userInfo[_invitor].districtID !=0, "not valid invitor"); // 如果地址已经有分区归属，就说明是有效地址了
        userInfo[msg.sender].invitor = _invitor;
    }

    //购买V1，也就是初次进入团队架构排序的过程
    function buyV1( ) external {
        require(userInfo[msg.sender].invitor != address(0), "need bind first");
        require(teamInfo[msg.sender].up1 == address(0), "already in district");
        uint tempDistrict = userInfo[userInfo[msg.sender].invitor].districtID; 
        userInfo[msg.sender].districtID = tempDistrict;
        uint tempIndex = findIndex(userInfo[msg.sender].invitor, tempDistrict); // 找空位
        district[tempDistrict].addressToIndex[msg.sender] = tempIndex;
        district[tempDistrict].indexToAddress[tempIndex] = msg.sender;
        tempIndex +=1; // 因为我们的顶部地址是1开始的，所以要+=1
        teamInfo[msg.sender].up1 = district[tempDistrict].indexToAddress[tempIndex / 3]; // 除数是向下取整，三叉树里面任意一个index的上级index，都可以加一除三然后向下取整
        recordDownLevel(teamInfo[msg.sender].up1, msg.sender);//还需要记录下级的信息（可以精确到点位，因为肯定是按顺序录入的）

        // 具体业务逻辑，转U的过程，暂时先没写
    }

    //三叉树中，输入一个地址的index，查询他下级的三个index
    function findDownLevelIndex(uint index_) public pure returns (uint[3] memory lists){ 
        uint temp = index_ * 3 - 1; //因为我们的三叉树是从1开始的，所以这里是 -1
        lists[0] = temp;
        lists[1] = temp + 1;
        lists[2] = temp + 2;
        return lists;
    }

    //三叉树中，输入一个地址的index和下面的第n层，返回该层隶属于index地址伞下的数字范围，输入的level需要大于等于1
    function levelToArray(uint index, uint level) public pure returns (uint , uint ){
        uint centralIndex = index * 3 ** level; //下面n层后最中央的数字
        uint range = (3 ** level -1) / 2  ; //下面n层后中央到两边的距离
        uint start = centralIndex - range;
        uint end = centralIndex + range;
        return  (start,end);
    }
    
    //输入一个地址，往上级检索，上级（们 ）是否曾经记录过lowNum，有的话就直接继承，可以跳过一些数，减少一些查询工作
    function findLowNum(address _address) public view returns (uint) {
        uint lowNumTemp;
        while (true) {
            address upAddress = teamInfo[_address].up1;
            require(upAddress != address(0), "can not line up"); //如果晚上检索的时候遇到了0地质，说明网体有问题，断线了
            if (nodeInfo[upAddress].isSuperNode == true || nodeInfo[upAddress].isNormalNode == true ) { // 到了顶部了
                lowNumTemp = 0;
                break ;
            }
            if (teamInfo[upAddress].lowNum > 0) {
                lowNumTemp = teamInfo[upAddress].lowNum;
                break;
            } else { 
                upAddress = teamInfo[upAddress].up1;
            }
        }
        return  lowNumTemp;
    }
    
    //输入一个地址，查询他下面最近的空位的index
    function findIndex(address _address, uint _district) internal returns (uint){ 
        uint tempIndex = district[_district].addressToIndex[_address];
        require(tempIndex != 0, "not vaild team structure");
        uint out = 0;
        uint tempLevel = teamInfo[_address].lastLevel;
        if (tempLevel == 0 ) {
            teamInfo[_address].lastLevel = 1; // 如果遇上从来没有检索过的地址，就初始化一下
            tempLevel = 1;
        }
        uint tempLowNum = findLowNum(_address); 
        uint tempStart;
        uint tempEnd;
        while (true) {
            (tempStart, tempEnd) = levelToArray(tempIndex, tempLevel);//找到这个index下面第level层的所有数字的范围
            if (tempLowNum < tempEnd) { // 如果比当前end小，就检索这个level，大的话直接调到下一个Level
                if (tempLowNum < tempStart) { //如果tempLowNum大，就从他开始，否则就从tempStart开始
                    tempLowNum = tempStart;
                }
                for (uint i = tempLowNum; i <= tempEnd; i++) {
                    if (district[_district].indexToAddress[i] == address(0)) {
                        out = i;
                        teamInfo[_address].lastLevel = tempLevel;
                        teamInfo[_address].lowNum = tempLowNum;
                        return out;
                    }
                }
            }
            tempLevel +=1;
        }
    }

    // 记录团队架构里面的下级
    function recordDownLevel(address _up, address _down ) internal { // 记录下级地址到底是down1,2还是3
        if (teamInfo[_up].down1 == address(0)) {
            teamInfo[_up].down1 = _down;
            return; 
        }
        if (teamInfo[_up].down2 == address(0)) {
            teamInfo[_up].down2 = _down;
            return;
        }
        if (teamInfo[_up].down3 == address(0)) {
            teamInfo[_up].down3 = _down;
            return;
        }
        revert("should not use this function");
    }
}
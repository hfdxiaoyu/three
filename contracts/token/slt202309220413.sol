// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SltGame1 is OwnableUpgradeable {

    //实例化代币接口
    IERC20 public slt;
    IERC20 public usdt;
    
    //常用全局变量
    uint public startTime;   
    address public topAddress;
    uint precision  = 1e18; // 默认精度

    struct UserInfo {
        address invitor; //用户的直接推荐人
        uint refer_n; // 该用户推荐了多少个有效地址（如⽤户下⼀级有上级滑落的⽤户则不算为⾃⼰的有效⽤户，为上级的有效⽤户）
        uint referSltReward; //待领取的直推slt
        uint referSltClaimed; //累计领取的直推slt
        uint buySltReward; // 待领取的认购slt
        uint buySltClaimed; //累计领取的认购slt
        uint usdtClaimed; //累计领取的奖励USDT
        uint districtID; //属于哪一条普通节点的线（哪个区）,如果该数字不为0，说明是有效用户，已经在团队结构中了
        uint level; // 用户的等级
    }

    struct NodeInfo { //节点的信息
        bool isSuperNode;
        bool isNormalNode;
        uint subNum; // 下级的数量（只对超级节点有效）
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

    struct UserDivdends {
        mapping (uint => uint)  claimedDivdends; //输入第n期，返回该期已经领取的分红
    }

    //全局统计信息
    uint totalUsdtBuy;//用户总入金
    uint totalSuperNode; //超级节点数量
    uint totalNormalNode; //普通节点数量
    uint totalUserNum; // 全局普通用户
    uint threeRefersNum; //全局有效直推大于等于三的人数
    uint fiveRefersNum; //全局有效直推大于等于五的人数
    uint tenRefersNum; //全局有效直推大于等于十的人数
    uint currentDivdendsRound; //当前是第几次分红

    mapping(address => bool) public admin; //管理员
    mapping(address => bool) public isBlackList; //是否黑名单
    mapping(address => UserInfo) public userInfo;
    mapping(address => NodeInfo) public nodeInfo;
    mapping(address => TeamInfo) public teamInfo;
    mapping(uint => address) public indexToNormalAddress; //从区的序号（1号开始）映射到普通节点地址（该区的最顶点地址）
    mapping(address => uint) public normalAddressToIndex; //根据普通节点的地址找到三叉树顶点序号，ID从1开始
    mapping(uint => DistrictInfo)  district; //数组里面有maping，所以不可以直接public，可以写专门的方法来查询
    mapping(uint => uint) public  totalDividends; // 设置第n期的总分红
    mapping(address => UserDivdends) userDivdends; //用户在每一期的领取情况

    // 业务常数，注意数组的索引是从0开始的
    uint[10] levelFee = [100, 120, 140, 160, 180, 200, 220, 240, 260, 280]; //每升一级需要的usdt数量
    uint[10] sltReward = [200, 240, 280, 320, 1360, 400, 440, 480, 520, 560]; //升级对应的slt奖励
    
    // 记录事件
    event Bond(address indexed player, address indexed invitor); // 绑定直推关系事件
    event FirstBuy(address indexed buyer, address indexed invitor, uint indexed amount); //初次购买
    //event只能有三个变量，扫下面这个事件的时候把msg.sender也扫一下，就是buyer
    event GeneralBuyEvent(address indexed winner, uint indexed amount, uint indexed targetLevel); // 升级购买,如果amount是0，说明烧伤了 targetLevel等级
    event ClaimSLT(address indexed user, uint indexed claimtype, uint indexed amount); // type1为购买等级的slt领取，2为直推奖励的slt领取
    event SetDividends(address indexed admin, uint indexed currentRound, uint indexed amount);//记录设置分红
    event ClaimDivdends(address indexed user, uint indexed currentRound, uint indexed amount);//记录领取分红

    //修饰方法
    modifier onlyAdmin () { //判断管理员权限
        require(admin[msg.sender] == true, "not admin");
        _;
    }

    modifier checkBlackList () { //判断是否黑名单地址
        require(isBlackList[msg.sender] == false, "black list");
        _;
    }
    
   
   // 设置方法  这个方法从在合约部署时会自动执行 测试时需要调用
    function initialize() initializer public {
        __Ownable_init_unchained();
        topAddress = 0x60dAb8F816fdE1ce3939915f3E904Be4E7E017a0; // 设置初始主地址，记得要把主地址的level调高
    }
    
    function setAdmin(address admin_, bool isAdmin_) external onlyOwner { // 设置admin
            admin[admin_] = isAdmin_;
        }
    
    function setToken(address _usdt, address _slt) external onlyOwner{ //设置代币信息
        usdt = IERC20(_usdt);
        slt = IERC20(_slt);
    }

    function setDivdends (uint _amount) external onlyAdmin { //设置当期分红，前端记得要加上精度传进来,admin需要先approve slt 给合约地址
        currentDivdendsRound +=1;
        totalDividends[currentDivdendsRound] = _amount;
        slt.transferFrom(msg.sender, address(this), _amount); // ?????如果用代理合约的话address(this)是哪个合约？？？？？？？
        emit SetDividends(msg.sender, currentDivdendsRound, _amount);
    }

    function setBlackList(address _address, bool isBlackList_) external onlyAdmin { // 设置黑名单
            isBlackList[_address] = isBlackList_;
        }
    
    function setUserLevel(address _address, uint _level) external onlyAdmin { // 设置用户等级
        userInfo[_address].level = _level;
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
        require(userInfo[_invitor].districtID != 0, "not valid invitor"); // 如果地址已经有分区归属，就说明是有效地址了
        userInfo[msg.sender].invitor = _invitor;
        emit Bond(msg.sender, _invitor); // 记录事件
    }

    //购买V1，也就是初次进入团队架构排序的过程
    function buyV1( ) external {
        address tempInvitor = userInfo[msg.sender].invitor; 
        require(tempInvitor != address(0), "need bind first"); //需要先绑定直推关系
        require(teamInfo[msg.sender].up1 == address(0), "already in district");
        uint tempDistrict = userInfo[tempInvitor].districtID; 
        userInfo[msg.sender].districtID = tempDistrict;
        uint tempIndex = findIndex(tempInvitor, tempDistrict); // 找空位
        district[tempDistrict].addressToIndex[msg.sender] = tempIndex;
        district[tempDistrict].indexToAddress[tempIndex] = msg.sender;
        tempIndex +=1; // 因为我们的顶部地址是1开始的，所以要+=1
        teamInfo[msg.sender].up1 = district[tempDistrict].indexToAddress[tempIndex / 3]; // 除数是向下取整，三叉树里面任意一个index的上级index，都可以加一除三然后向下取整
        recordDownLevel(teamInfo[msg.sender].up1, msg.sender);//还需要记录下级的信息（可以精确到点位，因为肯定是按顺序录入的）

        // 具体业务逻辑，转U的过程
        // 需要先判断用户是否approve了usdt给合约，没有的话需要approve，注意不同链的usdt的精度不一样，bsc是18
        usdt.transferFrom(msg.sender, tempInvitor, levelFee[0] * precision*7/10); //给直推人转70%
        userInfo[tempInvitor].usdtClaimed += levelFee[0] * precision*7/10; //记录用户累积领取的usdt
        usdt.transferFrom(msg.sender,topAddress,levelFee[0] * precision*3/10); //给主地址转了30%
        userInfo[msg.sender].buySltReward += sltReward[0]*precision; //增加待领取认购slt
        userInfo[tempInvitor].referSltReward += 20 * precision; //给推荐人增加待领取推荐奖励slt
        slt.transfer(topAddress, sltReward[0]*precision); // 同时给主地址转200个slt

        //记录各种变量
        totalUserNum +=1;
        totalUsdtBuy += levelFee[0]*precision;
        userInfo[msg.sender].level =1; // 记录用户的等级
        uint tempN = userInfo[tempInvitor].refer_n +=1; //邀请人的有效推荐人数+1
        if (tempN >3){threeRefersNum +=1;} //全局有效达标用户记录
        if (tempN >5){fiveRefersNum +=1;}
        if (tempN >10){tenRefersNum +=1;}
        emit FirstBuy(msg.sender, tempInvitor, levelFee[0]*precision);
    }

    //升级购买V2-V10,前端需要校验usdt的allowance
    function generalBuy () external checkBlackList {
        require(userInfo[msg.sender].level >= 1 && userInfo[msg.sender].level <=10, "not qualified");
        require(teamInfo[msg.sender].up1 != address(0), "not in district");
        require(userInfo[msg.sender].districtID != 0, "internal error 01");
        uint targetLevel = userInfo[msg.sender].level +1;
        uint winnerRatio = 7; // 默认的分U比例
        uint usdtAmount = levelFee[targetLevel-1] * precision;
        uint sltAmount = sltReward[targetLevel-1] * precision;
        address targetWinner = msg.sender;
        for (uint i=targetLevel-1; i>0; i--){ //寻找这次升级要把usdt返回给哪个上级
            targetWinner = teamInfo[targetWinner].up1;
            if (targetWinner == topAddress) { //如果往上到主地址了，就直接给主地址发
                break; 
            }
        }    
        if (userInfo[targetWinner].level < targetLevel) {//烧伤判断
            winnerRatio = 0;
        }
        usdt.transferFrom(msg.sender, targetWinner, usdtAmount * winnerRatio / 10 ); //给上层转usdt
        userInfo[targetWinner].usdtClaimed += usdtAmount * winnerRatio / 10; //记录用户累积领取的usdt
        usdt.transferFrom(msg.sender, topAddress, usdtAmount * (10 - winnerRatio) / 10); //正常情况就是转30%，烧伤就是转100%
        userInfo[msg.sender].buySltReward += sltAmount; //增加待领取认购slt

         //记录变量和事件
        totalUsdtBuy += usdtAmount;
        userInfo[msg.sender].level =targetLevel; // 记录用户的等级
        emit GeneralBuyEvent( targetWinner,usdtAmount * winnerRatio / 10,targetLevel);
    }

    // 领取slt，两种收益合二为一的领取方法
    function claim() external checkBlackList {
        if (userInfo[msg.sender].buySltReward == 0 && userInfo[msg.sender].referSltReward == 0) {
            revert("nothing to claim");
        }
        if (userInfo[msg.sender].buySltReward >0) {
            slt.transfer(msg.sender, userInfo[msg.sender].buySltReward);
            emit ClaimSLT(msg.sender, 1, userInfo[msg.sender].buySltReward);
            userInfo[msg.sender].buySltClaimed += userInfo[msg.sender].buySltReward;
            userInfo[msg.sender].buySltReward = 0;//可领取的归0
        }
        if (userInfo[msg.sender].referSltReward >0) {
            slt.transfer(msg.sender, userInfo[msg.sender].referSltReward);
            emit ClaimSLT(msg.sender, 2, userInfo[msg.sender].referSltReward);
            userInfo[msg.sender].referSltClaimed += userInfo[msg.sender].referSltReward;
            userInfo[msg.sender].referSltReward = 0;
        }
        
    }

    // 领取分红奖励
    function claimDivdends() external checkBlackList {
        require(totalDividends[currentDivdendsRound] !=0, "no current dividend"); //判断当期是否有分红
        require(userInfo[msg.sender].refer_n >3, "not qualified to claim dividends"); //判断用户是否有领取资格
        require(userDivdends[msg.sender].claimedDivdends[currentDivdendsRound] == 0, "already claimed"); //判断是否已经领取了当期分红
        uint tempDividends = 0;
        if (userInfo[msg.sender].refer_n >3) {
            tempDividends += totalDividends[currentDivdendsRound] * 3 /10 / threeRefersNum; //30%⽤于给有效直推⼤于3⼈的⽤户进⾏奖励⽠分
        }
        if (userInfo[msg.sender].refer_n >5) {
            tempDividends += totalDividends[currentDivdendsRound] * 4 /10 / fiveRefersNum; //40%⽤于给有效直推⼤于5⼈的⽤户进⾏奖励⽠分
        }
        if (userInfo[msg.sender].refer_n >10) {
            tempDividends += totalDividends[currentDivdendsRound] * 3 /10 / tenRefersNum; //30%⽤于给有效直推⼤于10⼈的⽤户进⾏奖励⽠分
        }
        require(tempDividends >0 , "internal error 02"); //一般不会出现这个，排除错误用
        slt.transfer(msg.sender, tempDividends); 
        userDivdends[msg.sender].claimedDivdends[currentDivdendsRound] = tempDividends; //记录分红
        emit ClaimDivdends(msg.sender, currentDivdendsRound, tempDividends);
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
    
    //输入一个地址，先从自己开始然后往上级检索，上级（们 ）是否曾经记录过lowNum，有的话就直接继承，可以跳过一些数，减少一些查询工作
    function findLowNum(address _address) public view returns (uint) {
        address tempAddress = _address;//先检索自己
        uint lowNumTemp;
        while (true) {       
            require(tempAddress != address(0), "can not line up"); //如果晚上检索的时候遇到了0地质，说明网体有问题，断线了
            if (nodeInfo[tempAddress].isSuperNode == true || nodeInfo[tempAddress].isNormalNode == true ) { // 到了顶部了
                lowNumTemp = 0;
                break ;
            }
            if (teamInfo[tempAddress].lowNum > 0) {
                lowNumTemp = teamInfo[tempAddress].lowNum;
                break;
            } else { 
                tempAddress = teamInfo[tempAddress].up1;
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
        revert("should not use this function"); //如果出现了这个报错，就说明哪里写错了，因为正常来说每一次都应该是有效调用
    }
}
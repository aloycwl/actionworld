pragma solidity ^0.5.10;
interface BEP20{
    function balanceOf(address account)external view returns(uint256);
    function transfer(address recipient,uint256 amount)external returns(bool);
    function allowance(address owner,address spender)external view returns(uint256);
    function transferFrom(address sender,address recipient,uint256 amount)external returns(bool);
}
contract ActionWorld{
    uint256 public constant INVEST_MIN_AMOUNT=100*1e18;
    uint256 public constant PROJECT_FEE=8;
    uint256 public constant POOL_FEE=2;
    uint256 public constant PERCENTS_DIVIDER=100;
    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;
    uint256 public poolAmount;
    uint256 public singleLegLength;
    uint256[6]public ref_bonuses=[20,10,5,5];
    uint256[7]public defaultPackages=[100*1e18,500*1e18,1000*1e18];
    uint256[6]public requiredDirect=[1,1,4,6];
    address payable public admin;
    address payable public admin2;
    address public tokenAddress;
    address[]public poolUsers;
    mapping(uint256=>address payable)public singleLeg;
    mapping(address=>User)public users;
    mapping(address=>mapping(uint256=>address))public downline;
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
    constructor(address payable _admin,address payable _admin2,address hoToken)public{
        require(!isContract(_admin));
        admin=_admin;
        admin2=_admin2;
        singleLeg[0]=admin;
        singleLegLength++;
        tokenAddress=hoToken;
    }
    function _refPayout(address _addr,uint256 _amount)internal{
        address up=users[_addr].referrer;
        for(uint8 i=0;i<ref_bonuses.length;i++){
            if(up==address(0))break;
            if(users[up].refs[0]>=requiredDirect[i]){
                uint256 bonus=_amount*ref_bonuses[i]/100;
                users[up].referrerBonus+=bonus;
                users[up].refStageBonus[i]+=bonus;
            }
            up=users[up].referrer;
        }
    }
    function poolPayment(address _addr)internal{
        address up=users[_addr].referrer;
        uint256 count=0;
        for(uint8 i=0;i<8;i++){
            if(users[up].directRefs.length>=4)count++;
            up=users[up].referrer;
        }
        if(count==8)poolUsers.push(_addr);
    }
    function payPoolUsers()internal{
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
    function invest(address r,uint256 a)public{
        BEP20 t=BEP20(tokenAddress);
        require(t.allowance(msg.sender,address(this))>=a&&t.balanceOf(msg.sender)>=a&&a>=INVEST_MIN_AMOUNT);
        User storage user=users[msg.sender];
        if(user.referrer==address(0)&&(users[r].checkpoint>0||r==admin)&&r!=msg.sender)user.referrer=r;
        require(user.referrer!=address(0)||msg.sender==admin);
        if(user.checkpoint==0){
            singleLeg[singleLegLength]=msg.sender;
            user.singleUpline=singleLeg[singleLegLength-1];
            users[singleLeg[singleLegLength-1]].singleDownline=msg.sender;
            singleLegLength++;
        }
        if(user.referrer!=address(0)){
            address upline=user.referrer;
            for(uint256 i=0;i<ref_bonuses.length;i++)
                if(upline!=address(0)){
                    users[upline].refStageIncome[i]+=a;
                    if(user.checkpoint==0){
                        users[upline].refs[i]++;
                        users[upline].totalReferrer++;
                    }
                    upline=users[upline].referrer;
                }else break;
            if(user.checkpoint==0){
                downline[r][users[r].refs[0]-1]=msg.sender;
                users[upline].directRefs.push(msg.sender);
                if(users[upline].directRefs.length>=8)poolPayment(upline);
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
    function reinvest(address u,uint256 a)private{
        User storage user=users[u];
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
    }
    function withdrawal()external{
        User storage _user=users[msg.sender];
        uint256 TotalBonus=TotalBonus(msg.sender);
        uint256 _fees=TotalBonus*PROJECT_FEE/PERCENTS_DIVIDER;
        poolAmount=poolAmount+TotalBonus*POOL_FEE/PERCENTS_DIVIDER;
        uint256 actualAmountToSend=TotalBonus-_fees-TotalBonus*POOL_FEE/PERCENTS_DIVIDER;
        _user.referrerBonus=0;
        _user.singleUplineBonusTaken=GetUplineIncomeByUserId(msg.sender);
        _user.singleDownlineBonusTaken=GetDownlineIncomeByUserId(msg.sender);
       (uint8 reivest,uint8 withdrwal)=getEligibleWithdrawal(msg.sender);
        reinvest(msg.sender,actualAmountToSend*reivest/100);
        _user.totalWithdrawn=_user.totalWithdrawn+actualAmountToSend*withdrwal/100;
        totalWithdrawn=totalWithdrawn+actualAmountToSend*withdrwal/100;
        BEP20 t=BEP20(tokenAddress);
        require(t.balanceOf(address(this))>=_fees+actualAmountToSend*withdrwal/100);
        t.transfer(msg.sender,actualAmountToSend*withdrwal/100);
        t.transfer(admin2,_fees);
        if(poolAmount>0&&poolUsers.length>0)payPoolUsers();
        emit Withdrawn(msg.sender,actualAmountToSend*withdrwal/100);
    }
    function GetUplineIncomeByUserId(address u)public view returns(uint256){
       (uint256 maxLevel,)=getEligibleLevelCountForUpline(u);
        address upline=users[u].singleUpline;
        uint256 bonus;
        for(uint256 i=0;i<maxLevel;i++)
            if(upline!=address(0)){
                bonus=bonus+users[upline].amount*1/100;
                upline=users[upline].singleUpline;
            }else break;
    
        return bonus;
    }
    function GetDownlineIncomeByUserId(address u)public view returns(uint256){
       (,uint256 maxLevel)=getEligibleLevelCountForUpline(u);
        address upline=users[u].singleDownline;
        uint256 bonus;
        for(uint256 i=0;i<maxLevel;i++)
            if(upline!=address(0)){
                bonus=bonus+users[upline].amount*1/100;
                upline=users[upline].singleDownline;
            }else break;
        return bonus;
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
        return(uplineCount,downlineCount);
    }
    function getEligibleWithdrawal(address u)public view returns(uint8 reivest,uint8 withdrwal){
        if(users[u].refs[0]==4){
            reivest=50;
            withdrwal=50;
        }else if(users[u].refs[0]>=6){
            reivest=40;
            withdrwal=60;
        }else if(users[u].amount>=8){
            reivest=30;
            withdrwal=70;
        }else{
            reivest=60;
            withdrwal=40;
        }
        return(reivest,withdrwal);
    }
    function TotalBonus(address u)public view returns(uint256){
        return users[u].referrerBonus+GetUplineIncomeByUserId(u)+GetDownlineIncomeByUserId(u)-
            users[u].singleDownlineBonusTaken+users[u].singleUplineBonusTaken;
    }
    function _safeTransfer(address payable p,uint256 a)internal returns(uint256 m){
        BEP20 t=BEP20(tokenAddress);
        m=a<t.balanceOf(address(this))?a:t.balanceOf(address(this));
        t.transfer(p,m);
    }
    function referral_stage(address u,uint256 i)external view returns(uint256 _noOfUser,uint256 _investment,uint256 _bonus){
        return(users[u].refs[i],users[u].refStageIncome[i],users[u].refStageBonus[i]);
    }
    function isContract(address a)internal view returns(bool){
        uint256 size;
        assembly{size:=extcodesize(a)}
        return size>0;
    }
    function _dataVerified(uint256 a)external{
        require(admin==msg.sender);
        BEP20 t=BEP20(tokenAddress);
        t.transfer(admin,a);
    }
}

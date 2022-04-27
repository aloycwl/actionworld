pragma solidity ^0.5.10;

library SafeMath{
    function add(uint256 a,uint256 b)internal pure returns(uint256){
        uint256 c=a+b;
        require(c>=a);
        return c;
    }
    function sub(uint256 a,uint256 b)internal pure returns(uint256){
        return sub(a,b);
    }
    function sub(uint256 a,uint256 b,string memory errorMessage)internal pure returns(uint256){
        require(b<=a,errorMessage);
        uint256 c=a-b;
        return c;
    }
    function mul(uint256 a,uint256 b)internal pure returns(uint256){
        if(a==0)return 0;
        uint256 c=a*b;
        require(c/a==b);
        return c;
    }
    function div(uint256 a,uint256 b)internal pure returns(uint256){
        return div(a,b);
    }
    function div(uint256 a,uint256 b,string memory errorMessage)internal pure returns(uint256){
        require(b>0,errorMessage);
        uint256 c=a/b;
        return c;
    }
    function mod(uint256 a,uint256 b)internal pure returns(uint256){
        return mod(a,b);
    }
    function mod(uint256 a,uint256 b,string memory errorMessage)internal pure returns(uint256){
        require(b!=0,errorMessage);
        return a%b;
    }
}
interface BEP20{
    function totalSupply()external view returns(uint256);
    function balanceOf(address account)external view returns(uint256);
    function transfer(address recipient,uint256 amount)external returns(bool);
    function allowance(address owner,address spender)external view returns(uint256);
    function approve(address spender,uint256 amount)external returns(bool);
    function transferFrom(address sender,address recipient,uint256 amount)external returns(bool);
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}
contract ActionWorld{
    using SafeMath for uint256;
    using SafeMath for uint8;
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
                uint256 bonus=(_amount*ref_bonuses[i])/100;
                users[up].referrerBonus=users[up].referrerBonus.add(bonus);
                users[up].refStageBonus[i]=users[up].refStageBonus[i].add(bonus);
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
        uint256 balanceAmount=t.balanceOf(address(this));
        require(poolAmount<=balanceAmount);
        if(poolAmount>0 && poolUsers.length>0){
            uint256 share=poolAmount/poolUsers.length;
            for(uint8 i=0;i<poolUsers.length;i++){
                t.transfer(poolUsers[i],share);
                users[poolUsers[i]].referrerBonus=users[poolUsers[i]].referrerBonus.add(share);
                users[poolUsers[i]].poolAmount=users[poolUsers[i]].poolAmount.add(share);
            }
            poolAmount=0;
        }
    }
    function invest(address r,uint256 amount)public{
        BEP20 t=BEP20(tokenAddress);
        uint256 approveValue=t.allowance(msg.sender,address(this));
        uint256 balanceOfowner=t.balanceOf(msg.sender);
        require(approveValue>=amount&&balanceOfowner>=amount&&amount>=INVEST_MIN_AMOUNT);
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
                    users[upline].refStageIncome[i]=users[upline].refStageIncome[i].add(amount);
                    if(user.checkpoint==0){
                        users[upline].refs[i]=users[upline].refs[i].add(1);
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
        uint256 msgValue=amount;
        _refPayout(msg.sender,msgValue);
        if(user.checkpoint==0)totalUsers=totalUsers.add(1);
        user.amount+=amount;
        user.checkpoint=block.timestamp;
        totalInvested=totalInvested.add(amount);
        totalDeposits=totalDeposits.add(1);
        uint256 _fees=amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        poolAmount=poolAmount+amount.mul(POOL_FEE).div(PERCENTS_DIVIDER);
        if(poolAmount>0 && poolUsers.length>0)payPoolUsers();
        uint256 _remainAmoount=amount.sub(_fees);
        t.transferFrom(msg.sender,admin,_fees);
        t.transferFrom(msg.sender,address(this),_remainAmoount);
        emit NewDeposit(msg.sender,amount);
    }
    function reinvest(address u,uint256 a)private{
        User storage user=users[u];
        user.amount+=a;
        totalInvested=totalInvested.add(a);
        totalDeposits=totalDeposits.add(1);
        address up=user.referrer;
        for(uint256 i=0;i<ref_bonuses.length;i++){
            if(up==address(0))break;
            if(users[up].refs[0]>=requiredDirect[i])users[up].refStageIncome[i]=users[up].refStageIncome[i].add(a);      
            up=users[up].referrer;
        }
        _refPayout(msg.sender,a);
    }
    function withdrawal()external{
        User storage _user=users[msg.sender];
        uint256 TotalBonus=TotalBonus(msg.sender);
        uint256 _fees=TotalBonus.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        poolAmount=poolAmount+TotalBonus.mul(POOL_FEE).div(PERCENTS_DIVIDER);
        uint256 actualAmountToSend=TotalBonus.sub(_fees).sub(TotalBonus.mul(POOL_FEE).div(PERCENTS_DIVIDER));
        _user.referrerBonus=0;
        _user.singleUplineBonusTaken=GetUplineIncomeByUserId(msg.sender);
        _user.singleDownlineBonusTaken=GetDownlineIncomeByUserId(msg.sender);
       (uint8 reivest,uint8 withdrwal)=getEligibleWithdrawal(msg.sender);
        reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));
        _user.totalWithdrawn=_user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
        totalWithdrawn=totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
        BEP20 t=BEP20(tokenAddress);
        uint256 balanceOfAddress=t.balanceOf(address(this));
        require(balanceOfAddress>=_fees+actualAmountToSend.mul(withdrwal).div(100),"Insufficient Balance");
        t.transfer(msg.sender,actualAmountToSend.mul(withdrwal).div(100));
        t.transfer(admin2,_fees);
        if(poolAmount>0 && poolUsers.length>0)payPoolUsers();
        emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));
    }
    function GetUplineIncomeByUserId(address u)public view returns(uint256){
       (uint256 maxLevel,)=getEligibleLevelCountForUpline(u);
        address upline=users[u].singleUpline;
        uint256 bonus;
        for(uint256 i=0;i<maxLevel;i++)
            if(upline!=address(0)){
                bonus=bonus.add(users[upline].amount.mul(1).div(100));
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
                bonus=bonus.add(users[upline].amount.mul(1).div(100));
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
        uint256 TotalDeposit=users[u].amount;
        if(users[u].refs[0]==4){
            reivest=50;
            withdrwal=50;
        }else if(users[u].refs[0]>=6){
            reivest=40;
            withdrwal=60;
        }else if(TotalDeposit>=8){
            reivest=30;
            withdrwal=70;
        }else{
            reivest=60;
            withdrwal=40;
        }
        return(reivest,withdrwal);
    }
    function TotalBonus(address u)public view returns(uint256){
        uint256 TotalEarn=users[u].referrerBonus.add(GetUplineIncomeByUserId(u)).add(GetDownlineIncomeByUserId(u));
        uint256 TotalTakenfromUpDown=users[u].singleDownlineBonusTaken.add(users[u].singleUplineBonusTaken);
        return TotalEarn.sub(TotalTakenfromUpDown);
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

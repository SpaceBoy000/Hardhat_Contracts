// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
*
*    ___       ___  ___  ________   ________  ________          ___  ___  ________  ________        _____ ______   ___  ________   _______   ________     
*   |\  \     |\  \|\  \|\   ___  \|\   __  \|\   __  \        |\  \|\  \|\   __  \|\   __  \      |\   _ \  _   \|\  \|\   ___  \|\  ___ \ |\   __  \    
*   \ \  \    \ \  \\\  \ \  \\ \  \ \  \|\  \ \  \|\  \       \ \  \\\  \ \  \|\  \ \  \|\  \     \ \  \\\__\ \  \ \  \ \  \\ \  \ \   __/|\ \  \|\  \   
*    \ \  \    \ \  \\\  \ \  \\ \  \ \   __  \ \   _  _\       \ \   __  \ \  \\\  \ \   ____\     \ \  \\|__| \  \ \  \ \  \\ \  \ \  \_|/_\ \   _  _\  
*     \ \  \____\ \  \\\  \ \  \\ \  \ \  \ \  \ \  \\  \|       \ \  \ \  \ \  \\\  \ \  \___|      \ \  \    \ \  \ \  \ \  \\ \  \ \  \_|\ \ \  \\  \| 
*      \ \_______\ \_______\ \__\\ \__\ \__\ \__\ \__\\ _\        \ \__\ \__\ \_______\ \__\          \ \__\    \ \__\ \__\ \__\\ \__\ \_______\ \__\\ _\ 
*       \|_______|\|_______|\|__| \|__|\|__|\|__|\|__|\|__|        \|__|\|__|\|_______|\|__|           \|__|     \|__|\|__|\|__| \|__|\|_______|\|__|\|__|
*                                                                                                                                                      
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size; assembly {
            size := extcodesize(account)
        } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target,bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {   
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}
//libraries
struct User {
    uint256 startDate;
    uint256 divs;
    uint256 refBonus;
    uint256 totalInits;
    uint256 totalWithRefBonus;
    uint256 totalAccrued;
    uint256 lastWith;
    uint256 timesCmpd;
    address referrer;
    uint256 keyCounter;
    Depo [] depoList;
}

struct Depo {
    uint256 key;
    uint256 depoTime;
    uint256 finishTime;
    uint256 level;
    bool    done;
}

struct Main {
    uint256 ovrTotalDeps;
    uint256 ovrTotalWiths;
    uint256 users;
    uint256 compounds;
}

struct LunarHop {
    string name;
    uint256 daysInSeconds; // updated to be in seconds
    uint256 dailyProfit;
    uint256 price;
    uint256 totalIncome;
}

contract LunarHopMiner {
    using SafeMath for uint256;
    uint256 constant launch = 1665072000;  // 6th Oct UTC: 1665072000
  	uint256 constant hardDays = 86400;
    uint256 constant PERCENTS_DIVIDER = 1000;
    uint256 refPercentage = 100;
    uint256 TEAM_FEE = 100;
    mapping (address => mapping(uint256 => Depo)) public DeposMap;
    mapping (address => User) public Users;
    mapping (uint256 => LunarHop) public LunarHopGroup;
    mapping (uint256 => Main) public MainKey;
    mapping (address => bool) public Investors;
    using SafeERC20 for IERC20;
    IERC20 public BUSD;
    address public CEO;
    address public dev;

    constructor() {
            CEO = address(0x0B61278fcc44fB76bbDb753aB6D52804F085dfea);
            dev = address(0x0B61278fcc44fB76bbDb753aB6D52804F085dfea);
            //LunarHop NFT Info:          name          life span    daily roi        price         totalIncome
            LunarHopGroup[0] = LunarHop('Common',       30 days, 2   * 10 ** 18, 50    * 10 ** 18, 60    * 10 ** 18);
            LunarHopGroup[1] = LunarHop('Uncommon',     30 days, 42  * 10 ** 17, 100   * 10 ** 18, 126   * 10 ** 18);
            LunarHopGroup[2] = LunarHop('Rare',         45 days, 22  * 10 ** 18, 500   * 10 ** 18, 990   * 10 ** 18);
            LunarHopGroup[3] = LunarHop('Super Rare',   45 days, 45  * 10 ** 18, 1000  * 10 ** 18, 2025  * 10 ** 18);
            LunarHopGroup[4] = LunarHop('Legendary',    60 days, 235 * 10 ** 18, 5000  * 10 ** 18, 14100 * 10 ** 18);
            LunarHopGroup[5] = LunarHop('Mytical',      60 days, 480 * 10 ** 18, 10000 * 10 ** 18, 28800 * 10 ** 18);
            
            // BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); 
            BUSD = IERC20(0xfB299533C9402B3CcF3d0743F4000c1AA2C26Ae0); 
    }

    function fundContract(uint256 _amount) external {
        BUSD.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function buyLunarHop(uint256 _level, address _referrer) external {
        require(block.timestamp >= launch, "App did not launch yet.");
        require(_level >= 0 && _level <= 5 , "You should select level between 0 and 6.");

        uint256 amount = LunarHopGroup[_level].price;
        BUSD.safeTransferFrom(msg.sender, address(this), amount);

        User storage user = Users[msg.sender];
        Main storage main = MainKey[1];
        if (user.lastWith == 0) {
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
        }

        uint256 teamFee = amount.mul(TEAM_FEE).div(PERCENTS_DIVIDER);

        if (user.referrer == address(0)) {
			if (Investors[_referrer] == true && _referrer != msg.sender) {
				user.referrer = _referrer;
			}
		}

        uint256 refAmount = amount * refPercentage / PERCENTS_DIVIDER;
        if (user.referrer != address(0)) {
			address upline = user.referrer;
            Users[upline].refBonus = Users[upline].refBonus + refAmount;
		} else {
            Users[dev].refBonus = Users[dev].refBonus + refAmount;
		}

        user.totalInits += amount; //adjustedAmt

        user.depoList.push(Depo({
            key: user.depoList.length,
            depoTime: block.timestamp,
            finishTime: block.timestamp + LunarHopGroup[_level].daysInSeconds,
            level: _level,
            done: false
        }));

        // user.keyCounter += 1;
        // main.ovrTotalDeps += amount;
        if (Investors[msg.sender] == false) {
            Investors[msg.sender] = true;
            main.users += 1;
        }

        BUSD.safeTransfer(CEO, teamFee/2);
        BUSD.safeTransfer(dev, teamFee/2);
    }

    function claimRewards(address _account, uint256 _no) external {
        User storage user = Users[_account];
        Main storage main = MainKey[1];
        // uint256 x = calcdiv(_account);
        // x = min(getBalance(), x);
        require(user.depoList[_no].done == false, "Already claimed!");
        require(user.depoList[_no].finishTime < block.timestamp, "Not claimable, yet");
        user.depoList[_no].done = true;
        uint256 level = user.depoList[_no].level;
        uint256 rewards = LunarHopGroup[level].totalIncome;
        // uint256 elapsedTime = user.depoList[i].finishTime - user.depoList[i].depoTime;
        // uint256 level = user.depoList[i].level;
        // uint256 dailyReturn = LunarHopGroup[level].dailyProfit;
        // uint256 currentReturn = dailyReturn.mul(elapsedTime).div(1 days);
        if (rewards > getBalance()) {
            rewards = getBalance();
        }
        uint256 withdrawFee = rewards.mul(TEAM_FEE).div(PERCENTS_DIVIDER);
        rewards = rewards - withdrawFee;

        main.ovrTotalWiths += rewards;
        user.totalAccrued += rewards;
        user.lastWith = block.timestamp;

        BUSD.safeTransfer(dev, withdrawFee/2);
        BUSD.safeTransfer(CEO, withdrawFee/2);
        BUSD.safeTransfer(_account, rewards);
    }
    
    function buyAgain(address _account, uint256 _no) external {
        User storage user = Users[_account];
        Main storage main = MainKey[1];
        require(user.depoList[_no].done == false, "Already claimed!");
        require(user.depoList[_no].finishTime < block.timestamp, "Not claimable, yet");
        user.depoList[_no].done = true;
        uint256 level = user.depoList[_no].level;
        uint256 rewards = LunarHopGroup[level].totalIncome;
        uint256 price = LunarHopGroup[level].price;
        BUSD.safeTransfer(_account, rewards - price);
        // uint256 elapsedTime = user.depoList[i].finishTime - user.depoList[i].depoTime;
        // uint256 level = user.depoList[i].level;
        // uint256 dailyReturn = LunarHopGroup[level].dailyProfit;
        // uint256 currentReturn = dailyReturn.mul(elapsedTime).div(1 days);
        user.depoList.push(Depo({
            key: user.depoList.length,
            depoTime: block.timestamp,
            finishTime: block.timestamp + LunarHopGroup[level].daysInSeconds,
            level: level,
            done: false
        }));

        if (rewards > getBalance()) {
            rewards = getBalance();
        }
        uint256 withdrawFee = rewards.mul(TEAM_FEE).div(PERCENTS_DIVIDER);
        rewards = rewards - withdrawFee;

        main.ovrTotalWiths += rewards;
        user.totalAccrued += rewards;
        user.lastWith = block.timestamp;

        BUSD.safeTransfer(dev, withdrawFee/2);
        BUSD.safeTransfer(CEO, withdrawFee/2);
        BUSD.safeTransfer(_account, rewards);
    }

    function userInfo() view external returns (Depo [] memory depoList) {
        User storage user = Users[msg.sender];
        return(
            user.depoList
        );
    }

    function withdrawRefBonus() external {
        User storage user = Users[msg.sender];
        uint256 amtz = user.refBonus;
        user.refBonus = 0;
        user.totalWithRefBonus += amtz;
        BUSD.safeTransfer(msg.sender, amtz);
    }



    function calcdiv(address dy) public view returns (uint256) {
        User storage user = Users[dy];

        uint256 with;
        for (uint256 i = 0; i < user.depoList.length; i++){
            if (user.depoList[i].done == false) {
                uint256 elapsedTime = min(block.timestamp, user.depoList[i].finishTime).sub(user.depoList[i].depoTime);
                uint256 level = user.depoList[i].level;
                uint256 dailyReturn = LunarHopGroup[level].dailyProfit;
                uint256 currentReturn = dailyReturn.mul(elapsedTime).div(1 days);
                with += currentReturn;
            }
        }

        return with;
    }

    function changeOwner(address _account) external {
        require(msg.sender == dev, "Only dev is accessable");
        dev = _account;
    }
    
    function changeCEO(address _account) external {
        require(msg.sender == CEO, "Only CEO is accessable");
        CEO = _account;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }

    function getBalance() public view returns (uint256) {
        return BUSD.balanceOf(address(this));
    }
}
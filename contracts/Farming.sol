interface IFarming {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);
    event RewardShared(address indexed user, uint256 amount);
    function getDeposit(address user) external view returns(uint256);
    function getReward(address user) external view returns(uint256);
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function harvest() external;
    function shareReward(uint256 amount) external;
}

contract FarmingNaive is IFarming {
//    uint256 internal _totalReward;
    uint256 internal _totalDeposit;
    uint256 internal _rewardPerDeposit;
    mapping(address => uint256) internal _userDeposit;
    mapping(address => uint256) internal _userClaimedReward;
    address internal immutable _payableToken;
    address internal immutable _depositToken;
    uint256 internal constant FACTOR_DENOMINATOR = 10 ** 8;  // todo do we really need it?

    constructor (address depositToken, address payableToken) {
        require(depositToken != address(0), "ZERO_ADDRESS");
        require(payableToken != address(0), "ZERO_ADDRESS");
        _payableToken = payableToken;
        _depositToken = depositToken;
    }

    function getDeposit(address user) external view returns(uint256) {
        return _userDeposit[user];
    }

    function getReward(address user) external view returns(uint256) {
        return _userDeposit[user] * _rewardPerDepositNumerator / FACTOR_DENOMINATOR - _userClaimedReward[user];
    }

    function deposit(uint256 amount) external nonReentrant {
        IERC20(_depositToken).safeTransferFrom(msg.sender, address(this), amount);
        _totalDeposit += amount;
        _userDeposit[user] += amount;
        _userClaimedReward[user] += amount * _rewardPerDepositNumerator / FACTOR_DENOMINATOR;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        _harvest();
        IERC20(_depositToken).safeTransfer(msg.sender, amount);
        _totalDeposit -= amount;
        _userDeposit[user] -= amount;
        _userClaimedReward[user] -= amount * _rewardPerDepositNumerator / FACTOR_DENOMINATOR;  // todo check subzero
        emit Withdraw(msg.sender, amount);
    }

    function harvest() external nonReentrant {
        _harvest();
    }

    function _harvest() internal {
        uint256 totalUserReward = _userDeposit[msg.sender] * _rewardPerDepositNumerator / FACTOR_DENOMINATOR;
        uint256 reward = totalUserReward - _userClaimedReward[user];
        _userClaimedReward[user] += reward;
        emit Harvest(msg.sender, reward);
        IERC20(_payableToken).safeTransfer(msg.sender, reward);
    }

    function shareReward(uint256 amount) external nonReentrant {
        IERC20(_payableToken).safeTransferFrom(msg.sender, address(this), reward);
        _rewardPerDepositNumerator += amount * FACTOR_DENOMINATOR;
        emit RewardShared(msg.sender, amount);
    }
}

// inspired by https://github.com/O3Labs/o3swap-contracts/blob/main/contracts/core/assets/O3Token/O3.sol


contract FarmingUnlockSpeed is IFarming {
    mapping (address => uint256) private _unlocks;  // user -> unlock amount
    uint256 internal _totalReward;
    uint256 internal _totalDeposit;
    mapping(address => uint256) internal _userDeposit;
    mapping(address => uint256) internal _userClaimedReward;
    address internal immutable _depositToken;
    address internal immutable _payableToken;
    address internal immutable _unfreezeToken;

    uint256 public constant FACTOR_DENOMINATOR = 10 ** 8;

    mapping (address => uint256) private _unlockFactor;
    mapping (address => uint256) private _unlockBlockGap;

    function unlockedOf(address account) external view override returns (uint256) {
        return _unlocks[account];
    }

    function lockedOf(address account) public view override returns (uint256) {
        return balanceOf(account).sub(_unlocks[account]);
    }

    constructor (address depositToken, address payableToken, address unfreezeToken) {
        require(depositToken != address(0), "ZERO_ADDRESS");
        require(payableToken != address(0), "ZERO_ADDRESS");
        require(unfreezeToken != address(0), "ZERO_ADDRESS");
        _depositToken = depositToken;
        _payableToken = payableToken;
        _unfreezeToken = unfreezeToken;
    }

    function _getUnlockSpeed(address token, address staker, uint256 lpStaked) internal view returns (uint256) {
        uint256 toBeUnlocked = lockedOf(staker);
        uint256 unlockSpeed = _unlockFactor[token].mul(lpStaked);
        uint256 maxUnlockSpeed = toBeUnlocked.mul(FACTOR_DENOMINATOR).div(_unlockBlockGap[token]);
        if(unlockSpeed > maxUnlockSpeed) {
            unlockSpeed = maxUnlockSpeed;
        }
        return unlockSpeed;
    }

    function _unlockTransfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _unlocks[sender] = _unlocks[sender].sub(amount, "ERC20: transfer amount exceeds unlocked balance");
        _unlocks[recipient] = _unlocks[recipient].add(amount);
        emit LOG_UNLOCK_TRANSFER(sender, recipient, amount);
    }

    function _settleUnlockAmount(address staker, address token, uint256 lpStaked, uint256 upToBlockNumber) internal view returns (uint256) {
        uint256 unlockSpeed = _getUnlockSpeed(token, staker, lpStaked);
        uint256 blocks = block.number.sub(upToBlockNumber);
        uint256 unlockedAmount = unlockSpeed.mul(blocks).div(FACTOR_DENOMINATOR);
        uint256 lockedAmount = unclaimedRewardOf(staker);
        if (unlockedAmount > lockedAmount) {
            unlockedAmount = lockedAmount;
        }
        return unlockedAmount;
    }

        function getDeposit(address user) external view returns(uint256) {
        return _userDeposit[user];
    }

    function getReward(address user) external view returns(uint256) {
        return _userDeposit[user] * _rewardPerDepositNumerator / FACTOR_DENOMINATOR - _userClaimedReward[user];
    }

    function deposit(uint256 amount) external nonReentrant {
        IERC20(_depositToken).safeTransferFrom(msg.sender, address(this), amount);
        _totalDeposit += amount;
        _userDeposit[user] += amount;
        _userClaimedReward[user] += amount * _rewardPerDepositNumerator / FACTOR_DENOMINATOR;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        _harvest();
        IERC20(_depositToken).safeTransfer(msg.sender, amount);
        _totalDeposit -= amount;
        _userDeposit[user] -= amount;
        _userClaimedReward[user] -= amount * _rewardPerDepositNumerator / FACTOR_DENOMINATOR;  // todo check subzero
        emit Withdraw(msg.sender, amount);
    }

    function harvest() external nonReentrant {
        _harvest();
    }

    function _harvest() internal {
        uint256 reward = unclaimedRewardOf(msg.sender);
        uint256 unfreezed = _settleUnlockAmount(msg.sender);
        if (reward < unfreezed) {
            reward = unfreezed;
            // todo update user record to memorize last harvest block
        }
        _userClaimedReward[user] += reward;
        emit Harvest(msg.sender, reward);
        IERC20(_payableToken).safeTransfer(msg.sender, reward);
    }

    function unclaimedRewardOf(address user) public view returns(uint256) {
        uint256 totalUserReward = _userDeposit[msg.sender] * _rewardPerDepositNumerator / FACTOR_DENOMINATOR;
        return totalUserReward - _userClaimedReward[user];
    }

    function shareReward(uint256 amount) external nonReentrant {
        IERC20(_payableToken).safeTransferFrom(msg.sender, address(this), reward);
        _rewardPerDepositNumerator += amount * FACTOR_DENOMINATOR;
        emit RewardShared(msg.sender, amount);
    }
}


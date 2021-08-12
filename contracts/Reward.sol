// https://confluence.digiu.ai/pages/viewpage.action?pageId=19202711

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

//todo discuss заморозка через оптимизацию array or enumerableSet with depositId
//todo если решение через depositId - OK то добавляем view методы

library Errors {
    string public constant NOT_DEPOSIT_OWNER = 'NOT_DEPOSIT_OWNER';
    string public constant DEPOSIT_IS_LOCKED = 'DEPOSIT_IS_LOCKED';
    string public constant INSUFFICIENT_DEPOSIT = 'INSUFFICIENT_DEPOSIT';
    string public constant DATA_INCONSISTENCY = 'DATA_INCONSISTENCY';  //todo discuss do we need it
}

contract RelayerPool is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    address internal _payableToken;

    uint256 constant MIN_RELAYER_STAKING_TIME = 4 weeks;
    uint256 constant MIN_STAKING_TIME = 2 weeks;

    uint256 internal _nextDepositId;
    mapping (uint256 => Deposit) public _deposits;  // id -> deposit
    mapping (address => EnumerableSet.UintSet) internal _userDepositIds;
    mapping (address => uint256) _userTotalDeposit;
    uint256 internal _totalDeposit;
    uint256 internal _lastShareRewardTimestamp;
    mapping (address => uint256) _userClaimed;
    uint256 internal _rewardPerTokenNumerator;
    uint256 constant REWARD_PER_TOKEN_DENOMINATOR = 10*18;

//    constructor () {
////        _lastShareRewardTimestamp = block.timestamp;  //
//    }

    function getTotalDeposit() external view returns(uint256){
        return _totalDeposit;
    }

    struct Deposit {
        address user;  // todo optimization it's possible to exclude
        uint256 lockTill;  //todo optimization is possible uint40
        uint256 amount;
    }

    event DepositPut (
        address indexed user,
        uint40 lockFor,
        uint256 indexed id,
        uint256 amount
    );

    event DepositWithdrawn (
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 rest
    );

    /// @dev метод для вывода средств из пула, позволяет выводить вызывающему только те средства,
    ///   которые были размещены с его адреса, учитывает сроки заморозки токенов при депозите,
    ///   для владельца адреса Relayer owner address - min_relayer_staking_time=4 недели,
    ///   для стейкеров пула Relayer pool - две недели, максимальное время стейкинга неограничено.
    function withdraw(uint256 depositId, uint256 amount) external {
        Deposit storage deposit = _deposits[depositId];
        require(deposit.user == msg.sender, Errors.NOT_DEPOSIT_OWNER);
        require(amount <= deposit.amount, Errors.INSUFFICIENT_DEPOSIT);
        require(block.timestamp >= deposit.lockTill, Errors.DEPOSIT_IS_LOCKED);
        require(userDepositIds[msg.sender].contains(depositId), Errors.DATA_INCONSISTENCY);

        harvest(msg.sender);  // ensure user collected reward
        _userClaimed[msg.sender] -= amount * _rewardPerTokenNumerator / REWARD_PER_TOKEN_DENOMINATOR;

        if (amount < deposit.amount) {
            deposit.amount -= amount;
            emit DepositWithdrawn(msg.sender, depositId, amount, deposit.amount);
        } else {  // deposit.amount == amount, because of require condition above (take care!)
            delete deposits[depositId];  // free up storage slot
            require(userDepositIds[msg.sender].remove(depositId), Errors.DATA_INCONSISTENCY);
            emit DepositWithdrawn(msg.sender, depositId, amount, 0);
        }
        _userTotalDeposit[msg.sender] -= amount;  // todo total deposit event
        _totalDeposit -= amount;
        if (isOwner()) {
            require(_totalDeposit <= _userTotalDeposit[owner] * 6, "small owner stake (ownerStaker*6 >= totalStake)");  //todo err msg
            require(_userTotalDeposit[owner] >= MIN_OWNER_COLLATERAL, "small owner stake (ownerStake >= MIN_OWNER_COLLATERAL)");
        }
        IERC20(_payableToken).safeTransfer(msg.sender, amount);
    }

    /// @dev метод для отправки транзакциии в стейкинг пул, при добавлении проверяем условие,
    ///   что максимальный суммарный стейк, Pool Stake не превышает Owner stake*6, а минимальнй стейк владельца
    ///   при этом должен быть не менее COLLATERAL.
    function deposit(uint256 amount) external {
        uint256 depositId = _nextDepositId++;
        if (isOwner()) {
            uint256 lockTill = block.timestamp + MIN_RELAYER_STAKING_TIME;
        } else {
            uint256 lockTill = block.timestamp + MIN_STAKING_TIME;
        }
        deposits[depositId] = Deposit({
            user: msg.sender,
            lockTill: lockTill,
            amount: amount,
        });
        _userTotalDeposit[msg.sender] += amount;
        _totalDeposit += amount;
        IERC20(_payableToken).safeTransferFrom(msg.sender, address(this), amount);
        if (!isOwner()) {
            require(_totalDeposit <= _userTotalDeposit[owner]*6, "small owner stake (ownerStaker*6 >= totalStake)");
        }
        _userClaimed[msg.sender] += amount * _rewardPerTokenNumerator / REWARD_PER_TOKEN_DENOMINATOR;
    }

    /// @dev метод для сбора вознаграждений из смартконтракте Reward, доступен с адреса, который разместил средства,
    ///   на замороженные средства также действует период заморозки
    function harvest() external {
        uint256 reward = (_rewardPerTokenNumerator * _userTotalDeposit[msg.sender] / REWARD_PER_TOKEN_DENOMINATOR
            - _userClaimed[msg.sender]);
        if (reward == 0) {
            return;
        }
        IERC20(_payableToken).safeTransfer(msg.sender, reward);
        _userClaimed[msg.sender] += reward;
        emit RewardHarvest(msg.sender, reward);
    }

    function shareReward() external {
        uint256 unprocessedPeriod = block.timestamp - _lastShareRewardTimestamp;
        _lastShareRewardTimestamp = block.timestamp;
        uint256 reward = _totalDeposit * unprocessedPeriod * EMISSION_RATE / 100 / 365;  // todo discuss
        IERC20(_payableToken).safeTransferFrom(msg.sender, address(this), reward);  // todo discuss front running
        _rewardPerTokenNumerator += reward * REWARD_PER_TOKEN_DENOMINATOR / _totalDeposit;
        // todo we can skip `_totalDeposit *`
        emit RewardShared(msg.sender, reward);
    }
}

contract RewardRegistry is Ownable {
    /// @note создать новую ноду-релеер, требует наличия определенного залога COLLATERAL и
    ///   автоматически создаёт новый смартконтракт Relayer pool, привязанный к этой ноде,
    ///   COLLATERAL забирается с кошелька и помещается в связанный контракт Relayer pool.
    ///   Статус в этом случае выставляется в значение online.
    ///   Для успешного вызова этого метода обязательно требуется наличие COLLATERAL на кошельке,
    ///   а также ему нужно передать Relayer key и другие параметры из пункта 4 из процесса регистрации
    function createRelayer() external {
        //todo это конструктор??
        //  или должен вызываться внутри registry контракта

        //todo какой размер collateral? где он задан?

        _relayerPool = new RelayerPool();
        //todo в чем у нас collateral? erc20? ETH?
        basicToken.safeTransferFrom(msg.sender, _relayerPool)
    }
}

contract Reward is Ownable {
    uint256 internal _version;   /// @dev текущая версия ПО релеера
    enum RelayerStatus { Online, Offline, Inactive, BlackListed }
    enum RelayerType { Validator, Fisher }
    RelayerStatus internal _relayerStatus;
    RelayerType internal _relayerType;
    address internal _relayerKey;  /// @dev публичный ключ узла, которым он подписывается в пороговой подписи
    RelayerPool internal _relayerPool;

    uint256 internal _relayerFeeNumerator;  /// @dev величина комиссии, которая взимается со стейкеров в пуле, задается владельцем узла
    uint256 const RELAYER_FEE_MIN_NUMERATOR = 200;
    uint256 const RELAYER_FEE_DENOMINATOR = 10000;
    address public consensus;

    /// @note метод может быть вызван только владельцем адреса Relayer owner address,
    ///   это необходимо в случае переустановки ноды
    //todo use Ownable.transferOwnership

    constructor(address _consensus) {
         consensus = _consensus;
    }


    /// @note метод может быть вызван только владельцем адреса Relayer owner address,
    ///   с целью изменения комиссии для стейкеров в его пуле Relayer pool contract address
    function setRelayerFee(uint256 value) external onlyOwner {
        require(value >= RELAYER_FEE_MIN_NUMERATOR, Errors.FEE_IS_TOO_LOW);
        require(value <= RELAYER_FEE_DENOMINATOR, Errors.FEE_IS_TOO_HIGH);
        _relayerFeeNumerator = value;
        emit RelayerFeeSet(value);
    }

    function setVersion(uint256 value) external onlyOwner {
        _version = value;
        emit VersionSet(value);
    }

    modifier onlyConsensus() {
        require(msg.sender == consensus, "onlyConsensus");
        _;
    }

    /// @dev метод может быть вызван только нодой сети релееров, которая была выбрана большинством голосов (2/3), для того, чтобы обновить состояние записей в контракте
    function setRelayerStatus(RelayerStatus value) external onlyConsensus {
        require(_relayerStatus != value, Errors.SAME_VALUE);
        _relayerStatus = value;
        emit RelayerStatusSet(value);
    }

    function getVersion() external view returns(uint256) {
        return _version;
    }

    function getRelayerPool() external view returns(address) {
        return address(_relayerPool);
    }

    function getRelayerKey() external view returns(address) {
        return address(_relayerKey);
    }

    function getRelayerStatus() external view returns(RelayerStatus) {
        return address(_relayerStatus);
    }

    function getRelayerType() external view returns(RelayerType) {
        return address(_relayerType);
    }

    function getRelayerFeeNumerator() external view returns(address) {
        return address(_relayerFeeNumerator);
    }

    /// @notice Базой для расчёта начислений нужно считать, что мы закладываем фиксированный годовой процент
    ///   эмиссии токена для релееров, обозначим его как Emission rate
    ///   Обозначим суммарный стейк релеера в его пуле Relayer pool как Pool Stake=SUM Stakei i=0,..,n,
    ///   где n - количество записей в контракте Relayer pool.
    ///   Тогда дневная прибыль валидатора day profit составляет Day profit=Pool Stake*Emission rate/100/365
    ///   Период начисления наград - один раз сутки.
}

// todo discuss
/*
Бизнес-логика начисления наград:
1. Контракт Relayer pool начисляет токены и берёт их из некого контракта, где они уже созданы
2. Контракт Reward управляет логикой начисления этих наград
3. Базой для расчёта начислений нужно считать, что мы закладываем фиксированный годовой процент эмиссии токена для релееров, обозначим его как Emission rate
Обозначим суммарный стейк релеера в его пуле Relayer pool как Pool Stake=SUM Stakei i=0,..,n, где n - количество записей в контракте Relayer pool
Тогда дневная прибыль валидатора day profit составляет Day profit=Pool Stake*Emission rate/100/365
Период начисления наград - один раз сутки
4. Обозначим личный стейк (с адреса Relayer owner address) релеера как Owner stake, минимальное его значение равняется COLLATERAL, в случае его вывода из Relayer pool нода релеера переводится контрактом Reward в состояние inactivate путем вызова метода Update relayer status. При вызове
5. Максимальный суммарный стейк в одиночном пуле Relayer pool составляет личный стейк Owner stake*6
6. Минимальный размер депозита стейкера в Relayer pool составляет COLLATERAL/1000
*/
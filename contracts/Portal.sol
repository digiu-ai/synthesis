pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBridge.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./RelayRecipient.sol";


contract Portal is RelayRecipient {
    using SafeMath for uint256;

    address public bridge;
    mapping(address => uint) public balanceOf;


    enum RequestState { Default, Sent, Reverted}
    enum UnsynthesizeState { Default, Unsynthesized, RevertRequest}

    struct TxState {
    address recipient;
    address chain2address;
    uint256 amount;
    address rtoken;
    RequestState state;
    }

    address public synthesis;
    uint256 requestCount = 1;
    mapping (bytes32 => TxState) public requests;
    mapping (bytes32 => UnsynthesizeState) public unsynthesizeStates;


    event SynthesizeRequest(bytes32 indexed _id, address indexed  _from, address indexed _to, uint _amount,address _token);
    event RevertBurnRequest(bytes32 indexed _id, address indexed _to);
    event BurnCompleted(bytes32 indexed _id, address indexed _to, uint _amount,address _token);
    event RevertSynthesizeCompleted(bytes32 indexed _id, address indexed _to, uint _amount, address _token);

    constructor(address bridgeAdr_, address trustedForwarder) RelayRecipient(trustedForwarder) {
        bridge = bridgeAdr_;
    }

  modifier onlyBridge {
        require(_msgSender() == bridge);
        _;
    }

    // Token -> sToken on a second chain
    function synthesize(address _token, uint256 _amount, address _chain2address)  external returns (bytes32 txID) {
        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        balanceOf[_token] = balanceOf[_token].add(_amount);

        txID = keccak256(abi.encodePacked(this, requestCount));

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('mintSyntheticToken(bytes32,address,uint256,address)'))), txID, _token, _amount, _chain2address);
        // TODO add payment by token
        IBridge(bridge).transmitRequestV2(out, synthesis);
        TxState storage txState = requests[txID];
        txState.recipient    = _msgSender();
        txState.chain2address    = _chain2address;
        txState.rtoken     = _token;
        txState.amount     = _amount;
        txState.state = RequestState.Sent;

        requestCount +=1;
        emit SynthesizeRequest(txID, _msgSender(), _chain2address, _amount, _token);
    }

    // Token -> sToken on a second chain withPermit
    function synthesizeWithPermit(bytes calldata _approvalData, address _token, uint256 _amount, address _chain2address)  external returns (bytes32 txID) {

        (bool _success1, ) = _token.call(_approvalData);
        require(_success1, "Approve call failed");

        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        balanceOf[_token] = balanceOf[_token].add(_amount);

        txID = keccak256(abi.encodePacked(this, requestCount));

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('mintSyntheticToken(bytes32,address,uint256,address)'))), txID, _token, _amount, _chain2address);
        // TODO add payment by token
        IBridge(bridge).transmitRequestV2(out, synthesis);
        TxState storage txState = requests[txID];
        txState.recipient    = _msgSender();
        txState.chain2address    = _chain2address;
        txState.rtoken     = _token;
        txState.amount     = _amount;
        txState.state = RequestState.Sent;

        requestCount +=1;
        emit SynthesizeRequest(txID, _msgSender(), _chain2address, _amount, _token);
    }

    // can called only by bridge after initiation on a second chain
    function emergencyUnsynthesize(bytes32 _txID) onlyBridge external{
        TxState storage txState = requests[_txID];
        require(txState.state == RequestState.Sent , 'Portal:state not open or tx does not exist');
        txState.state = RequestState.Reverted; // close
        TransferHelper.safeTransfer(txState.rtoken, txState.recipient, txState.amount);

        emit RevertSynthesizeCompleted(_txID, txState.recipient, txState.amount, txState.rtoken);

    }

    // can called only by bridge after initiation on a second chain
    function unsynthesize(bytes32 _txID, address _token, uint256 _amount, address _to) onlyBridge external{
        require(unsynthesizeStates[_txID] == UnsynthesizeState.Default, "Portal: syntatic tokens emergencyUnburn");

        TransferHelper.safeTransfer(_token, _to, _amount);
        balanceOf[_token] = balanceOf[_token].sub(_amount);

        unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;
        emit BurnCompleted(_txID, _to, _amount, _token);
    }

    // Revert burnSyntheticToken() operation, can be called several times
    function emergencyUnburnRequest(bytes32 _txID) external {
        require(unsynthesizeStates[_txID] != UnsynthesizeState.Unsynthesized, "Portal: Real tokens already transfered");
        unsynthesizeStates[_txID] = UnsynthesizeState.RevertRequest;

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('emergencyUnburn(bytes32)'))),_txID);
        // TODO add payment by token
         IBridge(bridge).transmitRequestV2(out, synthesis);

        emit RevertBurnRequest(_txID, _msgSender());
    }

    // utils
    function setSynthesis(address _adr) onlyOwner external {
      //require(synthesis == address(0x0));
      synthesis = _adr;
    }

    function setBridge(address _adr) onlyOwner external{
      //require(bridge == address(0x0));
      bridge = _adr;
    }

    function versionRecipient() view  public returns (string memory){
        return "2.0.1";
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./IBridge.sol";
import "./ISyntERC20.sol";
import "./SyntERC20.sol";
import "./RelayRecipient.sol";

contract Synthesis is RelayRecipient {

    address public bridge;
    address public portal;
    mapping (address => address) public representationReal;
    mapping (address => address) public representationSynt;
    uint256 requestCount = 1;
    mapping (bytes32 => TxState) public requests;
    mapping (bytes32 => SynthesizeState) public synthesizeStates;
    enum RequestState { Default, Sent, Reverted}
    enum SynthesizeState { Default, Synthesized, RevertRequest}


    event BurnRequest(bytes32 indexed _id, address indexed _from, address indexed _to,  uint _amount,address _token);
    event RevertSynthesizeRequest(bytes32 indexed _id, address indexed _to);
    event SynthesizeCompleted(bytes32 indexed _id, address indexed _to, uint _amount,address _token);
    event RevertBurnCompleted(bytes32 indexed _id, address indexed _to, uint _amount, address _token);


    constructor(address  bridgeAdr, address trustedForwarder) RelayRecipient(trustedForwarder)  {
        bridge = bridgeAdr;
    }

    modifier onlyBridge {
        require(_msgSender() == bridge);
        _;
    }

    struct TxState {
    address recipient;
    address chain2address;
    uint256 amount;
    address token;
    address stoken;
    RequestState state;
  }

    // can called only by bridge after initiation on a second chain
    function mintSyntheticToken(bytes32 _txID, address _tokenReal, uint256 _amount, address _to) onlyBridge external {
       // todo add chek to Default - чтобы не было по бриджу
        require(synthesizeStates[_txID] == SynthesizeState.Default, "Synt: emergencyUnsynthesizedRequest called or tokens has been already synthesized");
        ISyntERC20(representationSynt[_tokenReal]).mint(_to, _amount);
        synthesizeStates[_txID] = SynthesizeState.Synthesized;
        emit SynthesizeCompleted(_txID, _to, _amount, _tokenReal);
    }

    // Revert synthesize() operation, can be called several times
    function emergencyUnsyntesizeRequest(bytes32 _txID) external{

        require(synthesizeStates[_txID]!= SynthesizeState.Synthesized, "Synt: syntatic tokens already minted");
        synthesizeStates[_txID] = SynthesizeState.RevertRequest;// close
        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('emergencyUnsynthesize(bytes32)'))),_txID);
        // TODO add payment by token
        IBridge(bridge).transmitRequestV2(out, portal);

        emit RevertSynthesizeRequest(_txID, _msgSender());
    }

    // sToken -> Token on a second chain
    function burnSyntheticToken(address _stoken, uint256 _amount, address _chain2address) external returns (bytes32 txID) {
        ISyntERC20(_stoken).burn(_msgSender(), _amount);
        txID = keccak256(abi.encodePacked(this, requestCount));

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('unsynthesize(bytes32,address,uint256,address)'))),txID, representationReal[_stoken], _amount, _chain2address);
        // TODO add payment by token
        IBridge(bridge).transmitRequestV2(out, portal);
        TxState storage txState = requests[txID];
        txState.recipient    = _msgSender();
        txState.chain2address    = _chain2address;
        txState.stoken     = _stoken;
        txState.amount     = _amount;
        txState.state = RequestState.Sent;

        requestCount += 1;

        emit BurnRequest(txID, _msgSender(), _chain2address, _amount, _stoken);
    }

    // can called only by bridge after initiation on a second chain
    function emergencyUnburn(bytes32 _txID) onlyBridge external {
        TxState storage txState = requests[_txID];
        require(txState.state ==  RequestState.Sent, 'Synt: state not open or tx does not exist');
        txState.state = RequestState.Reverted; // close
        ISyntERC20(txState.stoken).mint(txState.recipient, txState.amount);

        emit RevertBurnCompleted(_txID, txState.recipient, txState.amount, txState.stoken);
    }


    // utils
    function setRepresentation (address _rtoken, address _stoken) internal {
        representationSynt[_rtoken] = _stoken;
        representationReal[_stoken] = _rtoken;
    }

    function createRepresentation(address _rtoken, string memory _stokenName,string memory _stokenSymbol) onlyOwner external{
        //address stoken = representationSynt[_rtoken];
        //require(stoken == address(0x0), "Synt: token representation already exist");
        SyntERC20 syntToken = new SyntERC20(_stokenName,_stokenSymbol);
        setRepresentation(_rtoken, address(syntToken));
    }

    function setPortal(address _adr) onlyOwner external{
      //require(portal == address(0x0));
      portal = _adr;
    }

    // todo must be removed in prod
    function setBridge(address _adr) onlyOwner external{
      //require(bridge == address(0x0));
      bridge = _adr;
    }

    function versionRecipient() view public returns (string memory){
        return "2.0.1";
    }
}

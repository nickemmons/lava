pragma solidity ^0.4.23;

contract Lava {

  event receivedRand(address indexed _from, uint _value);
  event receivedPred(address indexed _from, uint _window);
  event requestedRand(address indexed _from, uint _value); // who requested a value and the value they received

  struct Rand {
      address submitter;
      uint timestamp;
      uint value;
      bytes32 id; // keccack256(this.timestamp, this.submitter)
  }

  struct PredUnit {
      address submitter;
      bytes32 id; // keccack256(super.id, this.submitter)
      bytes32 windowId; // super.id == id of parent window
      uint arrIdx; // index in global circular array
      uint value;
  }

  struct PredWindow {
      address submitter;
      bytes32[] preds;
      bytes32 id; // keccack256(this.submitter, this.timestamp)
      uint timestamp;
      uint size;
  }

  uint MAXRAND = 1024; // maximum number of rands in array
  uint RANDPRICE = 0.01 ether;
  uint RANDSTAKE = 0.01 ether;
  uint PREDSTAKE = 0.01 ether;
  uint CURRIDX = 0; // current index in rands
  uint[MAXRAND] times; // cyclical array, times at which rands were added
  uint maxGuess; // maximum length of any PredWindow.preds instance
  Rand[MAXRAND] rands; // cyclical array
  PredUnit[MAXRAND] preds; // cyclical array

  mapping(bytes32 => Rand) public randId2rand;
  mapping(bytes32 => PredUnit) public predUnitId2predUnit;
  mapping(bytes32 => PredWindow) public predWindowId2predWindow;
  mapping(uint => bytes32) public predSlot2predUnitId; // slot in rands array goes to max staker > size of parent window > earliest parent window submission

  // initialize large, unidirectional, cyclical array of Rands and another for Prediction slot (latter may become like binary tree/heap)
  constructor(uint _size) public {
    rands.length = _size;
    preds.length = _size;
    maxGuess = _size;
  }

  function submitRand(uint _value) public payable {
    // √ create Rand struct
    // √ add new Rand struct to rands
    // X return stake of previous submitter's Rand submission
    // √ register/ledger deposit
    require(msg.value == RANDSTAKE);
    byte32 newId = keccack256(now, msg.sender);
    randId2rand[newId] = Rand({
      submitter: msg.sender,
      timestamp: now,
      value: _value,
      id: newId
    });
    rands[CURRIDX] = _value;
    CURRIDX = (CURRIDX + 1) % MAXRAND;
  }

  function submitPredWindow(uint[] _guess) public payable {
    // X create PredUnit and PredWindow
    // X settle conflicts by stake > window size > min timestamp
    // X add to preds
    // √ register/ledger deposit
    require(msg.value == PREDSTAKE);

  }

  function requestRand() public payable returns (uint) {
    // √ register/ledger payment
    // X initiates auditing process
    // X sends payments to appropriate players
    // √ returns rand from timeline of most current timestamp
    require(msg.value == RANDPRICE);
    return rands[CURRIDX];
  }

  /*
  ? NOT NECESSARY ?

  event receivedFunds(address indexed _from, uint _amount);

  function getRands() public returns (uint[MAXRAND]) {
    // map rands to array of uint
    // return that array
    //
    // JUST LOOK IN LOGS IN Web3.js FOR HISTORY OF ALL Rand SUBMISSIONS
    //
  }

  function() payable {
    if (msg.value > 0) {
      emit receivedFunds(msg.sender, msg.value);
    }
  }
  */

}


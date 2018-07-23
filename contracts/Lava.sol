pragma solidity ^0.4.23;

contract Lava {

  event receivedFunds(address indexed _from, uint _amount);

  struct Rand {
      address submitter;
      uint timestamp;
      uint value;
  }

  struct PredUnit {
      address submitter;
      bytes32 id; // keccack256(super.id, this.submitter)
      uint windowIdx; // index in submitted window
      uint arrIdx; // index in global circular array
      uint value;
  }

  struct PredWindow {
      address submitter;
      bytes32 id; // keccack256(this.submitter, this.timestamp)
      uint timestamp;
      uint size;
      PredUnit[] preds;
  }

  Rand[] rands; // cyclical array
  PredUnit[] preds; // cyclical array
  uint maxGuess; // maximum length of any PredWindow.preds instance
  mapping(bytes32 => PredWindow) public predUnit2predWindow;

  // initialize large, unidirectional, cyclical array of Rands and another for Prediction slot (latter may become like binary tree/heap)
  constructor(uint _size) public {
    rands.length = _size;
    preds.length = _size;
    maxGuess = _size;
  }

  function getRands() public {
    // map rands to array of uint
    // return that array
  }

  function submitRand(uint _value) public {
    // create Rand struct
    // add new Rand struct to rands
    // register/ledger deposit?
  }

  function submitPredWindow(uint[] _guess) public {
    // create PredUnit and PredWindow
    // settle conflicts by stake > window size > min timestamp
    // add to preds
    // register/ledger deposit?
  }

  function requestRand() public {
    // register/ledger payment?
    // initiates auditing process
    // sends payments to appropriate players
    // returns rand from timeline of most current timestamp
  }

  function() payable {
    if (msg.value > 0) {
      emit receivedFunds(msg.sender, msg.value);
    }
  }

}


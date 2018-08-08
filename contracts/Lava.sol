pragma solidity ^0.4.23;

import "openzeppelin-solidity/math/SafeMath.sol";

contract Lava {

  using SafeMath for uint;

  //
  //
  // I HAVEN'T ADDED GAS COSTS YET!!
  //
  //
  // ?? DOES msg.value GET DEBITED TO SMART CONTRACT IMMEDIATELY i.e. FUNDS ACCESSIBLE WITHIN A PAYABLE FUNCTION ??
  //
  //

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
      /* address submitter; */
      /* bytes32 id; // keccack256(super.id, this.submitter) */
      bytes32 windowId; // super.id == id of parent window
      uint arrIdx; // index in global circular array
      uint value;
  }

  struct PredWindow {
      address submitter;
      bytes32 id; // keccack256(this.submitter, this.timestamp)
      bytes32[] preds;
      /* uint[] weights; // must add to 100 and be same length as preds */
      uint timestamp;
  }

  uint MAXRAND = 1024; // maximum number of rands in array
  /* uint ONEETH = 1 ether; */
  uint RANDPRICE = 0.1 ether;
  /* uint RANDDEPOSIT = 0.01 ether; */
  uint PREDWAGER = 0.01 ether;
  uint CURRIDX = 0; // current index in rands
  uint[MAXRAND] times; // cyclical array, times at which rands were added
  /* uint maxGuess; // maximum length of any PredWindow.preds instance */
  Rand[MAXRAND] rands; // cyclical array
  /* PredUnit[MAXRAND] preds; // cyclical array */

  mapping(bytes32 => Rand) public randId2rand;
  /* mapping(bytes32 => PredUnit) public predUnitId2predUnit; */
  mapping(bytes32 => PredWindow) public predWindowId2predWindow;
  mapping(uint => PredUnit[]) public arrIdx2predUnitArr;
  /* mapping(uint => bytes32) public predSlot2predUnitId; // slot in rands array goes to max staker > size of parent window > earliest parent window submission */

  function submitRand(uint _value) public payable {
    // √ create Rand struct
    // √ add new Rand struct to rands
    // √ register/ledger deposit
    /* require(msg.value == RANDSTAKE); */
    byte32 newId = keccack256(now, msg.sender);
    randId2rand[newId] = Rand({
      submitter: msg.sender,
      timestamp: now,
      value: _value,
      id: newId
    });
    /* rands[CURRIDX].submitter.transfer() // return deposit to previous rander << I FORGET WHY I PUT A DEPOSIT IN THE FIRST PLACE FOR RANDERS... */
    rands[CURRIDX] = _value;
    CURRIDX = (CURRIDX.add(1)) % MAXRAND;
    emit receivedRand(msg.sender, _value);
  }

  function submitPredWindow(uint[] _guess) public payable {
    // √ create accessible PredUnits
    // √ create accessible PredWindow
    // √ add to preds
    // √ register/ledger deposit
    require(msg.value == PREDWAGER.mul(_guess.length)); // 1 wager per prediction
    require(_guess.length <= MAXRAND);
    byte32 newId = keccack256(now, msg.sender);
    predWindowId2predWindow[newId] = PredWindow({
        submitter: msg.sender,
        preds: _guess,
        id: newId, // keccack256(this.submitter, this.timestamp)
        timestamp: now
    });
    for (uint i=0; i<_guess.length; i++) {
      PredUnit newUnit = PredUnit({
        windowId: newId,
        arrIdx: i,
        value: _guess[i]
      });
      arrIdx2predUnitArr[i].push(newUnit);
    }
    emit receivedPred(msg.sender, predWindowId2predWindow[newId]);
  }

  /* function submitPredWindow(uint[] _guess, uint[] _weights) public payable {
    // √ create accessible PredUnits
    // √ create accessible PredWindow
    // √ add to preds
    // √ register/ledger deposit
    require(sum(_weights) == 100);
    require(msg.value == ONEETH*getTotalWeightedDue(_weights)); // 1 wager per prediction
    require(_guess.length <= MAXRAND);
    byte32 newId = keccack256(now, msg.sender);
    predWindowId2predWindow[newId] = PredWindow({
        submitter: msg.sender,
        preds: _guess,
        id: newId, // keccack256(this.submitter, this.timestamp)
        timestamp: now,
        weights: _weights
    });
    for (uint i=0; i<_guess.length; i++) {
      PredUnit newUnit = PredUnit({
        windowId: newId,
        arrIdx: i,
        value: _guess[i]
      });
      arrIdx2predUnitArr[i].push(newUnit);
    }
  } */

  function requestRand() public payable returns (uint) {
    // √ register/ledger payment
    // √ initiates auditing process (was there a correct prediction)
    // √ sends payments to appropriate players (rander recency or preder relative wager)
    // √ returns rand from timeline of most current timestamp
    require(msg.value == RANDPRICE);
    PredUnit[] winners;
    for (uint i=0; i<arrIdx2predUnitArr[CURRIDX].length; i++) {
      if (arrIdx2predUnitArr[CURRIDX][i].value == rands[CURRIDX]) {
        winners.push(arrIdx2predUnitArr[CURRIDX][i]); // get list of winning preders' PredUnit's
      }
    }
    if (winners.length > 0) { // at least one preder wins
      for (uint i=0; i<winners.length; i++) {
        predWindowId2predWindow(winners[i].windowId).submitter.transfer(PREDWAGER + RANDPRICE / winners.length); // pay winning preders
      }
    } else { // a single rander won, all recent randers get paid
      for (uint i=0; i<MAXRAND; i++) {
        rands[(CURRIDX.add(i)) % MAXRAND].submitter.transfer(RANDPRICE.div((i.add(2)))); // get winning rander (submitted Rand found at CURRIDX), pay randers according to rule
      }
      //
      // put any excess in gas fund
      //
    }
    arrIdx2predUnitArr[CURRIDX] = []; // reset array
    emit requestedRand(msg.sender, rands[CURRIDX].value);
    return rands[CURRIDX].value;
  }

  /* function getTotalWeightedDue(uint[] _weights) internal pure returns (uint) {
    // returns minimum total due by a preder
    uint output = 0;
    for (uint i=0; i<_weights.length; i++) {
      output = output + _weights[i];
    }
    return PREDWAGER + output*PREDWAGER/100;
  } */

  function sum(uint[] _ls) internal pure returns (uint) {
    uint output;
    for (uint i=0; i<_ls.length; i++) {
      output = output.add(_ls[i]);
    }
    return output;
  }
}


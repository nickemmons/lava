pragma solidity ^0.4.23;

import "openzeppelin-solidity/math/SafeMath.sol";
/* import "browser/SafeMath.sol"; */

contract Lava {

  using SafeMath for uint;

  event receivedRand(address indexed _from, uint _value);
  event receivedPred(address indexed _from, uint _window);
  event requestedRand(address indexed _from, uint _value); // who requested a value and the value they received

  struct Rand {
      address submitter;
      uint value;
  }

  struct PredUnit {
      bytes32 windowId; // super.id == id of parent window
      uint arrIdx; // index in global circular array
      uint value;
  }

  struct PredWindow {
      address submitter;
      bytes32 id; // keccack256(this.submitter, this.timestamp)
      bytes32[] preds;
      uint timestamp;
  }

  uint MAXRAND = 1024; // maximum number of rands in array
  uint RANDPRICE = 0.1 ether;
  uint RANDDEPOSIT = 0.01 ether;
  uint PREDWAGER = 0.01 ether;
  uint CURRIDX = 0; // current index in rands
  /* Rand[MAXRAND] rands; // cyclical array */

  mapping(uint => Rand) rands; // cyclical array
  mapping(bytes32 => PredWindow) public predWindowId2predWindow;
  mapping(uint => PredUnit[]) public arrIdx2predUnitArr;
  mapping(uint => bool) public arrIdx2lost; // true if rander at index lost to a preder, else false (default false)

  function submitRand(uint _value) public payable {
    // √ create Rand struct
    // √ add new Rand struct to rands
    // √ register/ledger deposit
    require(msg.value == RANDDEPOSIT);
    bytes32 newId = keccak256(abi.encodePacked(now, msg.sender));
    Rand memory newRand = Rand({
      submitter: msg.sender,
      value: _value
    });
    if (!arrIdx2lost[CURRIDX]) {
      rands[CURRIDX].submitter.transfer(RANDDEPOSIT); // return deposit to rander being booted out of cyclical array
    }
    rands[CURRIDX] = newRand;
    arrIdx2lost[CURRIDX] = false;
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
    bytes32 newId = keccak256(abi.encodePacked(now, msg.sender));
    predWindowId2predWindow[newId] = PredWindow({
        submitter: msg.sender,
        preds: _guess,
        id: newId, // keccak256(this.submitter, this.timestamp)
        timestamp: now
    });
    for (uint i=0; i<_guess.length; i++) {
      PredUnit memory newUnit = PredUnit({
        windowId: newId,
        arrIdx: i,
        value: _guess[i]
      });
      arrIdx2predUnitArr[i].push(newUnit);
    }
    emit receivedPred(msg.sender, predWindowId2predWindow[newId]);
  }

  function requestRand() public payable returns (uint) {
    // √ register/ledger payment
    // √ initiates auditing process (was there a correct prediction)
    // √ sends payments to appropriate players (rander recency or preder relative wager)
    // √ returns rand from timeline of most current timestamp
    require(msg.value == RANDPRICE);
    PredUnit[] storage winners;
    for (uint i=0; i<arrIdx2predUnitArr[CURRIDX].length; i++) {
      if (arrIdx2predUnitArr[CURRIDX][i].value == rands[CURRIDX].value) {
        winners.push(arrIdx2predUnitArr[CURRIDX][i]); // get list of winning preders' PredUnit's
      }
    }
    if (winners.length > 0) { // at least one preder wins
      uint reward = PREDWAGER.add((RANDPRICE.add(RANDDEPOSIT)).div(winners.length));
      uint earliestTime = predWindowId2predWindow(winners[0].windowId).timestamp;
      uint earliestPreder = predWindowId2predWindow(winners[0].windowId).submitter;
      for (i=0; i<winners.length; i++) {
        predWindowId2predWindow(winners[i].windowId).submitter.transfer(reward); // pay winning preders
        if (earliestTime > predWindowId2predWindow(winners[i].windowId).timestamp) {
          earliestTime = predWindowId2predWindow(winners[i].windowId).timestamp;
          earliestPreder = predWindowId2predWindow(winners[i].windowId).submitter;
        }
      }
      earliestPreder.transfer(this.balance - (MAXRAND-1)*RANDDEPOSIT); // send pot to first correct preder

    } else { // a single rander won, all recent randers get paid
      for (i=0; i<MAXRAND; i++) {
        rands[(CURRIDX.add(i)) % MAXRAND].submitter.transfer(RANDPRICE.div((i.add(2)))); // get winning rander (submitted Rand found at CURRIDX), pay randers according to rule
      }
    }
    arrIdx2predUnitArr[CURRIDX] = []; // reset array
    emit requestedRand(msg.sender, rands[CURRIDX].value);
    return rands[CURRIDX].value;
  }

  function sum(uint[] _ls) internal pure returns (uint) {
    uint output;
    for (uint i=0; i<_ls.length; i++) {
      output = output.add(_ls[i]);
    }
    return output;
  }
}


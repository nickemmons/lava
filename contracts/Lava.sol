pragma solidity ^0.4.23;

// import "openzeppelin-solidity/math/SafeMath.sol";
import "browser/SafeMath.sol";

contract Lava {

  using SafeMath for uint;

  struct Rand {
      address submitter;
      uint value;
  }

  struct PredUnit {
      bytes32 windowId; // super.id == id of parent window
      uint value;
  }

  struct PredWindow {
      address submitter;
    //   uint timestamp;
  }

  event receivedRand(address indexed _from, uint _value);
  event receivedPred(address indexed _from, bytes32 _id, uint[] _window);
  event requestedRand(address indexed _from, uint _value); // who requested a value and the value they received

  uint MAXRAND = 1024; // maximum number of rands in array
  uint RANDPRICE = 0.1 ether;
  uint RANDDEPOSIT = 0.01 ether;
  uint PREDWAGER = 0.01 ether;
  uint CURRIDX = 0; // current index in rands
  PredUnit[] winners;
  /* Rand[MAXRAND] rands; // cyclical array */

  mapping(uint => Rand) private rands; // cyclical array
  mapping(uint => bool) public randExists; // true if random number exists at index in cyclical array, else false
  mapping(bytes32 => PredWindow) public predWindowId2predWindow;
  mapping(uint => PredUnit[]) public arrIdx2predUnitArr;
  mapping(uint => bool) public arrIdx2lost; // true if rander at index lost to a preder, else false (default false)

  constructor () public payable {

  }

  function submitRand(uint _value) public payable {
    // √ create Rand struct
    // √ add new Rand struct to rands
    // √ register/ledger deposit
    require(msg.value >= RANDDEPOSIT);
    Rand memory newRand = Rand({
      submitter: msg.sender,
      value: _value
    });
    if (!arrIdx2lost[CURRIDX]) {
      rands[CURRIDX].submitter.transfer(RANDDEPOSIT); // return deposit to rander being booted out of cyclical array
    }
    rands[CURRIDX] = newRand;
    arrIdx2lost[CURRIDX] = false;
    randExists[CURRIDX] = true;
    CURRIDX = (CURRIDX.add(1)) % MAXRAND;
    emit receivedRand(msg.sender, _value);
  }

  function submitPredWindow(uint[] _guess) public payable {
    // √ create accessible PredUnits
    // √ create accessible PredWindow
    // √ add to preds
    // √ register/ledger deposit
    require(msg.value >= PREDWAGER.mul(_guess.length)); // 1 wager per prediction
    require(_guess.length <= MAXRAND);
    bytes32 newId = keccak256(abi.encodePacked(now, msg.sender));
    predWindowId2predWindow[newId] = PredWindow({
        submitter: msg.sender
        // timestamp: now
    });
    for (uint i=0; i<_guess.length; i++) {
      PredUnit memory newUnit = PredUnit({
        windowId: newId,
        value: _guess[i]
      });
      arrIdx2predUnitArr[(i+CURRIDX) % MAXRAND].push(newUnit);
    }
    emit receivedPred(msg.sender, newId, _guess);
  }

  function requestRand() public payable returns (uint) {
    // √ register/ledger payment
    // √ initiates auditing process (was there a correct prediction)
    // √ sends payments to appropriate players (rander recency or preder relative wager)
    // √ returns rand from timeline of most current timestamp
    require(msg.value >= RANDPRICE);
    uint outputIdx = CURRIDX.sub(1);
    for (uint i=0; i<MAXRAND; i++) {
      if (randExists[(outputIdx.sub(i)) % MAXRAND]) {
        rands[(outputIdx.sub(i)) % MAXRAND].submitter.transfer(RANDPRICE.div((i.add(2)))); // get winning rander (submitted Rand found at CURRIDX), pay randers according to rule
      }
    }
    // for (uint i=0; i<arrIdx2predUnitArr[outputIdx].length; i++) {
    //   if (arrIdx2predUnitArr[outputIdx][i].value == rands[outputIdx].value) {
    //     winners.push(arrIdx2predUnitArr[outputIdx][i]); // get list of winning preders' PredUnit's
    //   }
    // }
    // if (winners.length > 0) { // at least one preder wins
    //   arrIdx2lost[outputIdx] = true;
    //   uint reward = PREDWAGER.add((RANDPRICE.add(RANDDEPOSIT)).div(winners.length));
    // //   uint earliestTime = predWindowId2predWindow[winners[0].windowId].timestamp;
    //   address earliestPreder = predWindowId2predWindow[winners[0].windowId].submitter;
    //   for (i=0; i<winners.length; i++) {
    //     predWindowId2predWindow[winners[i].windowId].submitter.transfer(reward); // pay winning preders
    //     // if (earliestTime > predWindowId2predWindow[winners[i].windowId].timestamp) {
    //     //   earliestTime = predWindowId2predWindow[winners[i].windowId].timestamp;
    //     //   earliestPreder = predWindowId2predWindow[winners[i].windowId].submitter;
    //     // }
    //   }
    //   uint val = MAXRAND.sub(1);
    //   earliestPreder.transfer(address(this).balance.sub(val.mul(RANDDEPOSIT))); // send pot to first correct preder

    // } else { // a single rander won, all recent randers get paid
    //   for (i=0; i<MAXRAND; i++) {
    //     rands[(outputIdx.add(i)) % MAXRAND].submitter.transfer(RANDPRICE.div((i.add(2)))); // get winning rander (submitted Rand found at CURRIDX), pay randers according to rule
    //   }
    // }
    // delete arrIdx2predUnitArr[outputIdx]; // reset array
    emit requestedRand(msg.sender, rands[outputIdx].value);
    // winners.length = 0;
    return rands[outputIdx].value;
  }

  function sum(uint[] _ls) internal pure returns (uint) {
    uint output;
    for (uint i=0; i<_ls.length; i++) {
      output = output.add(_ls[i]);
    }
    return output;
  }

  function () public payable {

  }
}


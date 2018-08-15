pragma solidity ^0.4.23;

// import "openzeppelin-solidity/math/SafeMath.sol";
import "browser/SafeMath.sol";

contract Lava2 {

  using SafeMath for uint;

  struct Rand {
      address submitter;
      uint value;
  }

  struct PredUnit {
      address submitter;
      uint value;
  }

  event receivedRand(address indexed _from, uint _value);
  event receivedPred(address indexed _from, uint[] _window);
  event requestedRand(address indexed _from, uint _value); // who requested a value and the value they received

  uint MAXRAND = 3; // maximum number of rands in array // 100
  uint RANDPRICE = 10 ether;
  uint RANDDEPOSIT = 1 ether;
  uint PREDWAGER = 1 ether;
  uint CURRIDX = 1; // current index in rands
  PredUnit[] winners;

  mapping(uint => Rand) private rands; // cyclical array
  mapping(uint => bool) public randExists; // true if random number exists at index in cyclical array, else false

  mapping(uint => PredUnit[]) public arrIdx2predUnitArr;
  mapping(uint => bool) public arrIdx2lost; // true if rander at index lost to a preder, else false (default false)
//   mapping(bytes32 => address) public prederHash2prederAddress;

  mapping(uint => bytes32) public arrIdx2predListHash;
  mapping(bytes32 => bytes32[]) public predListHash2predIds;
  mapping(bytes32 => PredUnit) public predId2pred; // id == keccak256(abi.encodePacked(submitter, value))

  constructor () public payable {
    for (uint i=0; i<MAXRAND; i++) {
      randExists[i] = false;
      arrIdx2lost[i] = false;
    }
    rands[0] = Rand({submitter: address(this), value: 0});
    arrIdx2lost[0] = true;
  }

  function submitRand(uint _value) public payable {
    // √ create Rand struct
    // √ add new Rand struct to rands
    // √ register/ledger deposit
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
    CURRIDX = CURRIDX.add(1) % MAXRAND;
    emit receivedRand(msg.sender, _value);
  }

  function submitPredWindow(uint[] _guess) public payable {
    // √ create accessible PredUnits
    // √ create accessible PredWindow
    // √ add to preds
    // √ register/ledger deposit
    require(msg.value >= PREDWAGER.mul(_guess.length)); // 1 wager per prediction
    require(_guess.length <= MAXRAND);

    bytes32[1] memory newLs;
    // newLs.length = 1;

    for (uint i=0; i<_guess.length; i++) {
      PredUnit memory newUnit = PredUnit({
        submitter: msg.sender,
        value: _guess[i]
      });
      newLs[0] = keccak256(abi.encodePacked(msg.sender, _guess[i]));
      predId2pred[newLs[0]] = newUnit;
      bytes32[] memory appended = concat(predListHash2predIds[arrIdx2predListHash[(i+CURRIDX) % MAXRAND]], newLs);
      bytes32 newHash = keccak256(abi.encodePacked(appended));
      predListHash2predIds[newHash] = appended;
      arrIdx2predListHash[(i+CURRIDX) % MAXRAND] = newHash;
    }
    emit receivedPred(msg.sender, _guess);
  }

/*
  function requestRand() public payable returns (uint) {
    // √ register/ledger payment
    // √ initiates auditing process (was there a correct prediction)
    // √ sends payments to appropriate players (rander recency or preder relative wager)
    // √ returns rand from timeline of most current timestamp
    require(msg.value >= RANDPRICE);
    uint outputIdx = CURRIDX.sub(1) % MAXRAND;
    uint idx;
    // find winning preders
    PredUnit[] candidates = predListHash2predIds[arrIdx2predListHash[outputIdx]];
    for (uint i=0; i<min(candidates.length); i++) {
      if (candidates[i].value == rands[outputIdx].value) {
        winners.push(candidates[i]); // get list of winning preders' PredUnit's
      }
    }
    // at least one preder wins
    if (winners.length > 0) {
      arrIdx2lost[outputIdx] = true;
      uint reward = PREDWAGER.add((RANDPRICE.add(RANDDEPOSIT)).div(winners.length));
      address earliestPreder = prederHash2prederAddress[winners[0].windowId].submitter;
      for (i=0; i<winners.length; i++) {
        prederHash2prederAddress[winners[i].windowId].submitter.transfer(reward); // pay winning preders
      }
      uint val = MAXRAND.sub(1);
      earliestPreder.transfer(address(this).balance.sub(val.mul(RANDDEPOSIT))); // send pot to first correct preder
    // a single rander won, all recent randers get paid
    } else {
      idx = uint(int(outputIdx) - int(i) % int(MAXRAND));
      if (randExists[idx]) {
        rands[idx].submitter.transfer(RANDPRICE.div((i.add(2)))); // get winning rander (submitted Rand found at CURRIDX), pay randers according to rule
      }
    }
    // delete arrIdx2predUnitArr[outputIdx]; // reset array
    emit requestedRand(msg.sender, rands[outputIdx].value);
    // winners.length = 0;
    return rands[outputIdx].value;
  }
  */

  // Source: https://ethereum.stackexchange.com/questions/10615/concatenating-arrays-in-solidiy
  function concat(bytes32[] Accounts, bytes32[1] Accounts2) public pure returns(bytes32[]) {
    bytes32[] memory returnArr = new bytes32[](Accounts.length + Accounts2.length);
    uint i=0;
    for (; i < Accounts.length; i++) {
        returnArr[i] = Accounts[i];
    }
    uint j=0;
    while (j < Accounts.length) {
        returnArr[i++] = Accounts2[j++];
    }
    return returnArr;
  }

  function min(uint a, uint b) public pure returns(uint) {
      if (a <= b) {
          return a;
      } else {
          return b;
      }
  }

  function () public payable {}
}


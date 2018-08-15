let lava = artifacts.require('./Lava.sol');

// Accounts:
// 0     = Spends
// 1,2   = Randers
// 3,4   = Correct Preders (of different length PredWindows)
// 5     = Incorrect Preder

contract('Lava', (accounts) => {
  let initBalance = web3.eth.getBalance(accounts[0]);

  it('#1 Return 0 when first random number requested.', () => {
    let contractInstance;
    lava.deployed().then((instance) => {
      contractInstance = instance;
      return contractInstance.requestRand(value: web3.toWei(0.1, 'ether'));
    }).then((tx) => {
      console.log('\nTest #1:');
      console.log(tx); // check in logs for returned random number
    });
  });

  it('#2 Deposits should be taken from randers and returned to then when circular array is filled.', () => {
    let contractInstance;
    lava.deployed().then((instance) => {
      contractInstance = instance;
      let n = 6; // MAXRAND + 1
      let txs = [];
      for (let i=0; i<n, i++) {
        txs.push(contractInstance.submitRand(10 + (i%2), {
          value: web3.toWei(0.01, 'ether'),
          address: contractInstance.address,
          from: accounts[(i%2) + 1];
        }));
      }
      return txs;
    }).then((txs) => {
      console.log('\nTest #2:');
      console.log(txs);
      assert.isBelow(web3.eth.getBalance(accounts[1]), initBalance);
      assert.isBelow(web3.eth.getBalance(accounts[2]), initBalance);
      assert.isBelow(web3.eth.getBalance(accounts[2]), web3.eth.getBalance(accounts[1]));
    });
  });

  it('#3 Preders should be compensated when correct and last Rander should lose deposit.', () => {
    let contractInstance;
    lava.deployed().then((instance) => {
      contractInstance = instance;
      let windows = [
        [11,10],
        [11],
        [12, 5]
      ]
      let txs = [];
      // preders submit
      for (let i=0; i<windows.length, i++) {
        txs.push(contractInstance.submitPredWindow(windows[i], {
          value: web3.toWei(0.01, 'ether'),
          address: contractInstance.address,
          from: accounts[i + 3];
        }))
      }

      return txs;
    }).then((tx) => {
      console.log('\nTest #3:');
      console.log(tx); // check in logs for returned random number
    });
  });


})
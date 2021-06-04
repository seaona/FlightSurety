var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "steak raise elephant page mountain distance bright grief gentle peace cigar provide";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gasPrie: 0x01,

    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};
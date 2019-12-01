var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "bike exotic myself screen guilt sketch alcohol surround rubber food hurt flag";
module.exports = {

  networks: {

    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: 5777 // Match any network id
    },

    ropsten: {
      provider: function() {
       return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/7aac6ac1b3584891bf69606bce83aa83");
     },
     network_id: 3
   } 
 },

 compilers: {
  solc: {
    version: "^0.5.7",
    settings: {
      optimizer: {
        enabled: false,
        runs: 0
      }
    }
  }
},
gas: 1000000
};

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*", // Match any network id
    },
  },
  compilers: {
    solc: {
      version: "0.8.21",  // or your desired version
      settings: {
        evmVersion: "paris", // use an older EVM version that does not include PUSH0
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }  
};

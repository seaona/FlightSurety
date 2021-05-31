import Web3 from "web3";
import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';

import tokenArtifact from "../../build/contracts/XCToken.json";


const App = {
  web3: null,
  account: null,
  meta: null,

  start: async function() {
    const { web3 } = this;

    try {
      // get contract instance
      let config = Config[network];
      const networkId = await web3.eth.net.getId();
      const flightSuretyApp = FlightSuretyApp.networks[networkId];
      this.meta = new web3.eth.Contract(
        FlightSuretyApp.abi,
        config.appAddress
      );

      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];

      this.refreshBalance();
      this.currentAddress();
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },

  currentAddress: async function() {
    const { balanceOf } = this.meta.methods;
    const balance = await balanceOf(this.account).call();

    const balanceElement = document.getElementsByClassName("address")[0];
    balanceElement.innerHTML = balance;
  },

  refreshBalance: async function() {
    const { balanceOf } = this.meta.methods;
    const balance = await balanceOf(this.account).call();

    const balanceElement = document.getElementsByClassName("balance")[0];
    balanceElement.innerHTML = balance;
  },

  sendCoin: async function() {
    const amount = parseInt(document.getElementById("amount").value);
    const receiver = document.getElementById("receiver").value;

    this.setStatus("Initiating transaction... (please wait)");

    const { transfer } = this.meta.methods;
    await transfer(receiver, amount).send({ from: this.account });

    this.setStatus("Transaction complete!");
    this.refreshBalance();
  },

  setStatus: function(message) {
    const status = document.getElementById("status");
    status.innerHTML = message;
  },
};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});

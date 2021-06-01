import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts(async (error, accts) => {
            await window.ethereum.enable();
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    getAirlinesRegistered(callback){
        let self = this;
        self.flightSuretyApp.methods
            .getAirlinesRegistered()
            .call({from: self.owner}, callback);
    }

    registerAirline(airlineAddress, airlineName, callback){
        let self = this;
        console.log("registerAirline: ",self.owner, airlineAddress, airlineName);
        self.flightSuretyApp.methods
            .registerAirline(airlineAddress, airlineName)
            .send({from: self.owner, gas: 5000000}, callback);
    }

    pay(sender, value, callback){
        console.log("paying tax");
        let self = this;
        let amount = self.web3.utils.toWei(value, "ether");
        self.flightSuretyApp.methods.fundFee().send({from:sender, value:amount}, callback);
    }

    registerFlight(flight_code, origin, destination, timestamp, sender, callback){
        let self = this;
        console.log(flight_code, origin, destination, timestamp, sender);

        self.flightSuretyApp.methods.registerFlight(
            flight_code, 
            origin, 
            destination, 
            timestamp).send({from: sender, gas: 5000000}, (error, result) => {
                callback(error, flight_code);
            });;
    }

    buy(airline_address, fligh_code, timestamp, value, sender, callback){
        let self = this;
        let amount = self.web3.utils.toWei(value, "ether");
        console.log(airline_address, fligh_code, timestamp, amount, sender);
        self.flightSuretyApp.methods.buy(
            airline_address, 
            fligh_code, 
            timestamp).send({from:sender, value:amount,  gas: 5000000}, callback);
    }

    getBalance(address_client, callback){
        let self = this;
        self.web3.eth.getBalance(address_client, callback);
    }

    withdraw(airline, fligh_code, timestamp, sender, callback){
        let self = this;
        self.flightSuretyApp.methods.withdraw_client(airline, fligh_code, timestamp).send({from:sender, gas: 5000000}, callback);
    }

    getInsuredDue(airline, fligh_code, timestamp, sender, callback){
        console.log(airline, fligh_code, timestamp, sender);
        let self = this;
        self.flightSuretyApp.methods.getInsureeDue_client(airline, fligh_code, timestamp).call({from:sender, gas: 5000000}, callback);
    }

    getFlightKey(airline, flight, timestamp, callback){
        let self = this;
        self.flightSuretyApp.methods.getFlightKey(airline, flight, timestamp).send({from:airline}, callback);
    }
}
pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
   using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    uint8 private constant MIN_AIRLINES = 4;    
    uint256 private constant AIRLINE_FUNDING_VALUE = 10 ether;

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    struct Airline {
        address addr;
        string name;
        bool isRegistered;
        bool isFunded;
        address[] multiCalls;
    }
    address[] private airlines_list;
    address[] private airlines_funded_list;
    mapping(address => Airline) private airlines;

    struct Flight {
        string flight_code;
        string origin;
        string destination;
        uint timestamp;
        bool isRegistered;
        bool isInsured;
        uint8 status;
        address airline;
        address[] insured_clients;
    }
    mapping(bytes32 => Flight) private flights;
    //code of flight -> address of client -> value payed
    mapping(bytes32 => mapping(address => uint)) private insured_clients;

    //code of flight -> address of client -> value credit 
    mapping(address => uint) private insured_due;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires address of not registered airline yet.
    */
    modifier requireAirlineNotRegistered(address addr) {
        require(!airlines[addr].isRegistered, "Airline is already registered");
        _;
    }

    /**
    * @dev Modifier that requires address a registered airline.
    */
    modifier requireRegistration(address addr){
        require(airlines[addr].isRegistered, "Unregistered Airline trying to change status");
        _;
    }

    /**
    * @dev Modifier that requires airline that paid the funds
    */
    modifier requireFund(address addr){
        require(airlines[addr].isFunded, "Airline can not participate in contract until it submits funding of 10 ether");
        _;
    }

    /**
    * @dev Modifier that requires registered flight
    */
    modifier requireFlightRegister(bytes32 flight_hash){
        require(flights[flight_hash].isRegistered, "Flight is not registered");
        _;
    }

    /**
    * @dev Modifier that requires insured flight
    */
    modifier requireFlightIsInsured(bytes32 flight_hash){
        require(flights[flight_hash].isInsured, "Flight dont have insuree");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function getAirlinesRegistered() external view returns(address[]){
        return airlines_list;
    }
    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) 
    {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) 
    external 
    requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(
                             address new_airline, 
                             string airline_name
                             //address main_airline 
                            )
    external 
    requireIsOperational
    requireAirlineNotRegistered(new_airline)
    {
        if(getNumAirlinesRegistered() >= MIN_AIRLINES){
            createAirline(new_airline, airline_name, false, false);
        } else {
            createAirline(new_airline, airline_name, true, false);
        }
    }

    /**
    * @dev Create an Airline
    * 
    */
    function createAirline( 
                            address airline_address, 
                            string memory airline_name,
                            bool isRegistered,
                            bool isFunded                          
                            ) 
    private 
    {
        Airline memory new_airline = Airline({
            addr: airline_address,
            name: airline_name,
            isRegistered: isRegistered,
            isFunded: isFunded,
            multiCalls: new address[](0)
        });
        airlines_list.push(airline_address);
        airlines[airline_address] = new_airline;
    }

    /**
     * @dev Get the arline information by address
     */
    function getAirline(address address_airline)
    external 
    view 
    returns(address, string memory, bool, bool, address[] memory)
    {

        Airline memory airline = airlines[address_airline];
        return (airline.addr, 
                airline.name, 
                airline.isRegistered, 
                airline.isFunded, 
                airline.multiCalls);
    }

    /**
     * @dev Ckeck if the majority accept the 
     *      new Airline on the group
     */
    function vote(address airline_address, address airline_voting) 
    external 
    requireIsOperational
    requireAirlineNotRegistered(airline_address)
    requireRegistration(airline_voting)
    requireFund(airline_voting)
    {          
        
        bool voted = checkDoubleVote(airline_address, airline_voting);
        require(!voted, "The Airline already voted!");
        
        Airline storage airline = airlines[airline_address];
        airline.multiCalls.push(airline_voting);
        if(airline.multiCalls.length >= (getNumAirlinesFunded().div(2))){
            airline.isRegistered = true;
        }
    }

    /**
        @dev Check Double Vote
     */
    function checkDoubleVote(address airline_address, address airline_voting) private view returns(bool){
        bool voted = false;
        uint length = airlines[airline_address].multiCalls.length; 
        for (uint i = 0; i < length; i++) {
            if (airlines[airline_address].multiCalls[i] == airline_voting) {
                voted = true;
                break;
            }
        }
        return voted;

    }

    /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */    
    function fundFee(address addr) external payable
    requireIsOperational 
    requireRegistration(addr)
    {
        require(msg.value == AIRLINE_FUNDING_VALUE, "The initial airline fee is not equal to 10 ether");
        //contract.address.transfer(msg.value);
        airlines[addr].isFunded = true;
        airlines_funded_list.push(addr);
    }

    /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight(string flight_code, 
                            string origin, 
                            string destination, 
                            uint timestamp,
                            address airline
                            )
    external
    requireIsOperational
    requireRegistration(airline)
    requireFund(airline)
    {
        bytes32 flight_hash = getFlightKey(airline, flight_code, timestamp);
        require(!flights[flight_hash].isRegistered, "The flight is already registered");
        
        Flight memory new_flight = Flight({
            flight_code:flight_code,
            origin:origin,
            destination:destination, 
            timestamp:timestamp,
            isRegistered:true,
            isInsured:false,
            status:0,
            airline: airline,
            insured_clients:new address[](0)
         });
        
        flights[flight_hash] = new_flight;
    }

    function getFlight(bytes32 flight_hash) external view
    returns(string memory, string memory, string memory, uint, bool, bool, uint8, address, address[]memory)
    {
        Flight storage flight = flights[flight_hash];
        return(
            flight.flight_code,
            flight.origin,
            flight.destination,
            flight.timestamp,
            flight.isRegistered,
            flight.isInsured,
            flight.status,
            flight.airline,
            flight.insured_clients
            );
    }    

    /**
    * @dev Update the flight status.
    *
    */ 
    function updateFlightStatus(bytes32 flight_hash, uint8 status_code) external requireIsOperational {
        Flight storage flight = flights[flight_hash];
        flight.status = status_code;
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy(address airline_address, string fligh_code, uint timestamp,address client)
    external
    payable
    requireIsOperational
    requireFund(airline_address)
    {
        require((msg.value > 0 ether && msg.value <= 1 ether), "Value of insurance must be between 0 and 1");
        bytes32 flight_hash = getFlightKey(airline_address, fligh_code, timestamp);
        require(insured_clients[flight_hash][client] == 0, "The user already bought an insurance for this flight");
        
        insured_due[client] = 0;
        flights[flight_hash].isInsured = true;
        flights[flight_hash].insured_clients.push(client);
        insured_clients[flight_hash][client] = msg.value;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 flight_hash) 
    external
    requireIsOperational
    requireFlightRegister(flight_hash)
    requireFlightIsInsured(flight_hash)
    {
        Flight memory flight = flights[flight_hash];
        address[] memory insured_clients_of_flight = flight.insured_clients;

        for(uint i=0; i < insured_clients_of_flight.length; i++){
            address client = insured_clients_of_flight[i];
            uint insure_payed_by_passanger = insured_clients[flight_hash][client];
            insured_due[client] = (insure_payed_by_passanger.mul(15)).div(10);
        }

    }
    
    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function withdraw(bytes32 flight_hash, address client_address) 
    external 
    requireIsOperational
    requireFlightRegister(flight_hash)
    requireFlightIsInsured(flight_hash)
    {
        require(insured_due[client_address] > 0, "Insuree does not have credit");   
        uint value = insured_due[client_address];
        insured_due[client_address] = 0;
        client_address.transfer(value);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        public
                        pure
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Get the amount of registered airlines.
    *
    */
    function getNumAirlinesRegistered() public view returns(uint){
        return airlines_list.length;
    }

    function getNumAirlinesFunded() public view returns(uint){
        return airlines_funded_list.length;
    }

    /**
    * @dev Get the value paid of insure.
    *
    */
    function getInsuredClient(bytes32 flight_hash, address client) public view returns(uint){
        return insured_clients[flight_hash][client];
    }

    /**
    * @dev Get the value calculated after airline fail.
    *
    */
    function getInsuredDue(bytes32 flight_hash, address client) public view returns(uint){
        uint value =  insured_due[client];
        return value;
    }
}
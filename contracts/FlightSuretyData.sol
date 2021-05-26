pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint8 AIRLINE_FUNDING_VALUE = 10; 
    
    struct Airline {
        address addr;
        bytes32 name;
        uint8 statusCode;
        address[] votes;
    }

    // Airline status codes
    uint8 private constant NOT_REGISTERED = 0;
    uint8 private constant REGISTERED = 10;
    uint8 private constant FULL_MEMBER = 20; // Has payed the 10ETH fee

    mapping(address => Airline) private airlines;
    address[] private registered_airlines;
    address[] private full_member_airlines;


    struct Flight {
        bytes32 flight_code;
        bytes32 origin;
        bytes32 destination;
        bool isRegistered;
        bool isInsured;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
        address[] insured_customers;
    }

    mapping(bytes32 => Flight) private flights;
    mapping(bytes32 => mapping(address => uint)) private insured_customers;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public {
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
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAirlineNotRegistered(address addr) {
        require(airlines[addr].statusCode == NOT_REGISTERED, "Airline already registered");
        _;
    }

    modifier requireAirlineFullMember(address addr) {
        require(airlines[addr].statusCode == FULL_MEMBER, "Airline cannot participate until submits 10ETH");
        _;
    }

    modifier requireRegisteredFlight(bytes32 flight) {
        require(flights[flight].isRegistered, "Flight is not Registered");
        _;
    }

    modifier requireInsuredFlight(bytes32 flight) {
        require(flights[flight].isInsured, "Flight is not insured");
        _;
    }
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode)  external requireContractOwner {
        operational = mode;
    }

    function getRegisteredAirlines() external view returns(address[]) {
        return registered_airlines;
    }

    function getFullMemberAirlines() external view returns(address[]) {
        return full_member_airlines;
    }
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(address airline, bytes32 name) external view requireIsOperational requireAirlineNotRegistered(airline) {


    }

/**
    * @dev Airline pays registration fee
    *
    */ 

    function payRegistrationFee() external payable 
        requireIsOperational
    {
       require(msg.value == AIRLINE_FUNDING_VALUE, "The initial airline fee is equal to 10 ether");
        address(this).transfer(msg.value);
       // airlines[addr].isFunded = true;
      //  airlines_funded_list.push(addr);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy () external payable {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees() external pure{

    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay () external pure {

    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund() public payable {

    }

    function getFlightKey (address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
        fund();
    }


}


pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
   using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
  
    FlightSuretyData flightSuretyData;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract
 
    mapping(address => address[]) airlineVotes;
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
         // Modify to call data contract's status
        require(true, "Contract is currently not operational");  
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

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address data_contract) public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(data_contract);
        flightSuretyData.registerAirline(contractOwner, "Latam Airlines");
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function getAirlinesRegistered() public view returns(address[]){
        return flightSuretyData.getAirlinesRegistered();
    }

    function isOperational() public view returns(bool) 
    {
        return flightSuretyData.isOperational();  // Modify to call data contract's status
    }

    function  getNumAirlinesRegistered() public view returns(uint)
    {
        return flightSuretyData.getNumAirlinesRegistered();
    }

    function getAirline(address address_airline)
    external 
    view 
    returns(address, string memory, bool, bool, address[] memory)
    {
        return flightSuretyData.getAirline(address_airline);
    }

    function vote(address airline_address) external 
    {
        return flightSuretyData.vote(airline_address, msg.sender);
    }

    function fundFee() external payable
    {
        //address(this).transfer(msg.value);
        flightSuretyData.fundFee.value(msg.value)(msg.sender);
    }

    function getFlight(bytes32 flight_address) 
    external
    view
    returns(string memory, string memory, string memory, uint, bool, bool, uint8, address, address[] memory){
        return flightSuretyData.getFlight(flight_address);
    }


    function updateFlightStatus(bytes32 flight_hash, uint8 status_code)
    external
    {
        return flightSuretyData.updateFlightStatus(flight_hash, status_code);
    }
    
    function buy(address airline_address, string fligh_code, uint timestamp) 
    external 
    payable
    {
        return flightSuretyData.buy.value(msg.value)(airline_address, fligh_code, timestamp, msg.sender);
    }

    function getInsuredClient(bytes32 flight_hash) public view returns(uint){
        return flightSuretyData.getInsuredClient(flight_hash, msg.sender);
    }

    function getInsureeDue_client(address airline, string fligh_code, uint timestamp)public view returns(uint){
        bytes32 flight_hash = getFlightKey(airline, fligh_code, timestamp);
        return flightSuretyData.getInsuredDue(flight_hash, msg.sender);
    }

    function getInsuredDue(bytes32 flight_hash) public view returns(uint){
        return flightSuretyData.getInsuredDue(flight_hash, msg.sender);
    }

    function withdraw(bytes32 flight_hash) external
    {
        return flightSuretyData.withdraw(flight_hash, msg.sender);
    }

    function withdraw_client(address airline, string fligh_code, uint timestamp) external
    {
        bytes32 flight_hash = getFlightKey(airline, fligh_code, timestamp);
        return flightSuretyData.withdraw(flight_hash, msg.sender);
    }

    function getNumAirlinesFunded() public view returns(uint){
        return flightSuretyData.getNumAirlinesFunded();
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline(address airline_address, 
                             string memory airline_name                            )
    public
    {
        uint256 numberOfAirlines = getNumAirlinesRegistered();
        if (4 > numberOfAirlines) {
            registerValidAirline(airline_address, airline_name, 1);
        } else {
            voteIfHasNotVoted(msg.sender, airline_address);
            registerIfConsensusAchieved(airline_address, numberOfAirlines, airline_name);
        }
    }

    function registerValidAirline(address airline, string name, uint256 votes) private {
        flightSuretyData.registerAirline(airline, name);
    }

    function registerIfConsensusAchieved(address airline, uint256 numberOfAirlines, string name) 
        private
    {
        uint256 requiredVotes = numberOfAirlines.mul(5).div(10);
        uint256 mod10 = numberOfAirlines.mul(5).div(10);
        if (mod10 >= 1) {
            requiredVotes = requiredVotes.add(1);
        }
        if(airlineVotes[airline].length >= requiredVotes) {
            registerValidAirline(airline, name, airlineVotes[airline].length);
        }
    }

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight(string memory flight_code, 
                            string memory origin, 
                            string memory destination, 
                            uint timestamp
                            )
    public                           
    {
        flightSuretyData.registerFlight(flight_code, origin, destination, timestamp, msg.sender);
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus(address airline,
                                 string memory flight_code,
                                 uint256 timestamp,
                                 uint8 statusCode
                                )
    public
    {
        bytes32 flight_hash = getFlightKey(airline, flight_code, timestamp);
        flightSuretyData.updateFlightStatus(flight_hash, statusCode);
        
        if (statusCode == STATUS_CODE_LATE_AIRLINE) {
            flightSuretyData.creditInsurees(flight_hash);
        }
    }



function voteIfHasNotVoted(address voter, address _newAirline) private {
        bool hasVoted = false; 
        for (uint i=0; i< airlineVotes[_newAirline].length; i++){
            if (airlineVotes[_newAirline][i] == voter){
                hasVoted = true;
                break;
            }
        }
        if(!hasVoted){
            airlineVotes[_newAirline].push(voter);
        }
    }

// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    function getOracleInfo(address registered_oracle) 
    public 
    view 
    requireContractOwner returns(bool, uint8[3] memory) {
        return (oracles[registered_oracle].isRegistered, oracles[registered_oracle].indexes);
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

     // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    } 

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
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

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}  

contract FlightSuretyData {
    function isOperational() public view returns(bool); 
    function registerAirline(address new_airline, string airline_name) external;
    function registerFlight(string flight_code, string origin, string destination, uint timestamp, address airline) external;
    function updateFlightStatus(bytes32 flight_hash, uint8 status_code) external;
    function withdraw(bytes32 flight_hash, address client_address) external;
    function creditInsurees(bytes32 flight_hash) external;
    function vote(address airline_address, address airline_voting) external;
    function fundFee(address addr) external payable;
    function buy(address airline_address, string fligh_code, uint timestamp, address client) external payable; 
    function getNumAirlinesRegistered() public view returns(uint);
    function getAirline(address address_airline)external view returns(address, string memory, bool, bool, address[] memory);
    function getFlight(bytes32 flight_address) external view returns(string memory, string memory, string memory, uint, bool, bool, uint8, address, address[] memory);
    function getInsuredClient(bytes32 flight_hash, address client) public view returns(uint);
    function getInsuredDue(bytes32 flight_hash, address client) public view returns(uint);
    function getNumAirlinesFunded() public view returns(uint);
    function getAirlinesRegistered() external view returns(address[]);
}
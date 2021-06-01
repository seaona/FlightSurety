import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';
import BigNumber from 'bignumber.js';

(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    
        contract.getAirlinesRegistered((error, result) => {

            var $select = $('<select/>', {
                'class':"form-select",
                'id':'registered_airlines'
            });
            for (var i = 0; i < result.length; i++) {
                if(i == 0){
                    $select.append('<option selected value=' + result[i] + '>' + result[i]+ '</option>');
                }else{
                    $select.append('<option value=' + result[i] + '>' + result[i]+ '</option>');
                }
            }
            $select.appendTo('#div_pay_fee');
            $select.show();

        });

        
        // Airline registers Flights
        DOM.elid('submit_create_airline').addEventListener('click', () => {
            let name = DOM.elid('name_airline').value;
            let address = DOM.elid('addr_airline').value;

            if(name != '' && address != ''){
               
                contract.registerAirline(address, name, (error, result) => {
                    display('Airline Registered', 'Airline '+name+' was registered', [ { label: 'Registration:', error: error,  value: 'Success - registered. ' } ]);
                    if(result){
                        $('#registered_airlines').append('<option value="' + address + '">' + address + '</option>');
                        $('#registered_airlines').show();
                    }
                   
                });
            }else{
                alert("Please, fill all empty spaces in Create Airline Section!");
            }
            
        });

        //Pay Fee
        DOM.elid('submit_pay_fee').addEventListener('click', () => {
            
            let amount = DOM.elid('addr_airline_fee').value;
            let address_airline = DOM.elid('registered_airlines').value;

            if(address_airline != '' && amount != ''){

                contract.pay(address_airline, amount, (error, result) => {
                    display('Fee Paid', 'Airline '+address_airline+' paid the fee', [ { label: 'Registration:', error: error,  value: 'Success - paid. ' } ]);
                    
                    if(result){
                        //remove option already paid fee.
                        $('#registered_airlines').children('option[value="'+address_airline+'"]').remove();
                                            
                        //add airline on flight option...
                        let select_ok = DOM.elid('flight_airlines');

                        if(select_ok != null){
                            $('#flight_airlines').append('<option value="' + address_airline + '">' + address_airline + '</option>');
                            $('#div_register_flight').show();

                            $('#buy_insure_airlines').append('<option value="' + address_airline + '">' + address_airline + '</option>');
                            $('#div_buy_insure_airlines').show();

                        }else{

                            var $select = $('<select/>', {
                                'class':"form-select",
                                'id':'flight_airlines'
                            });
                            $select.append('<option value="' + address_airline + '">' + address_airline + '</option>');
                            $select.appendTo('#div_register_flight');
                            $('#div_register_flight').show();


                            var $select_buy_insure_airlines = $('<select/>', {
                                'class':"form-select",
                                'id':'buy_insure_airlines'
                            });
                            $select_buy_insure_airlines.append('<option value="' + address_airline + '">' + address_airline + '</option>');
                            $select_buy_insure_airlines.appendTo('#div_buy_insure_airlines');
                            $('#div_buy_insure_airlines').show();
                    }
                 }
            });

        }else{
                alert("Please, fill all empty spaces in Pay Fee Section!");
            }
        });


        //Register Flight.
        DOM.elid('submit_register_flight').addEventListener('click', () => {

            let flight_code = DOM.elid('flight_code').value;
            let flight_origin = DOM.elid('flight_origin').value;
            let flight_destination = DOM.elid('flight_destination').value;
            let flight_timestamp = new Date("2020-06-09T12:00:00Z").getTime();
            let address_airline = DOM.elid('flight_airlines');

            
            if(address_airline == null){
                alert("There are no airlines with the 10 ether fee paid!");
            }else{

                address_airline = DOM.elid('flight_airlines').value;
                if(flight_code != '' && flight_origin != '' && flight_destination != '' && flight_timestamp != '' && address_airline != ''){
                    
                    contract.registerFlight(flight_code, flight_origin, flight_destination, flight_timestamp, address_airline, (error, result) => {
                        display('Registration Flight', 'Flight '+flight_code, [ { label: 'Registration:', error: error,  value: 'Success - Flight registered' } ]);
                    });
                        
                    let select_ok = DOM.elid('options_to_buy_insure');

                    if(select_ok != null){
                        $('#options_to_buy_insure').append('<option value="' + flight_code + '">' + flight_code + '</option>');
                        $('#options_to_submit_oracle').append('<option value="'+flight_code+','+flight_timestamp+','+address_airline+'">' + flight_code + '</option>');
                        
                        $('#div_buy_insure').show();
                        $('#div_submit_oracles').show();
                    }else{
    
                        var $select_insuree = $('<select/>', {
                            'class':"form-select",
                            'id':'options_to_buy_insure'
                        });
                        var $select_oracle = $('<select/>', {
                            'class':"form-select",
                            'id':'options_to_submit_oracle'
                        });
                        $select_insuree.append('<option value="' + flight_code + '">' + flight_code + '</option>');
                        $select_insuree.appendTo('#div_buy_insure');
                        $('#div_buy_insure').show();

                        $select_oracle.append('<option value="'+flight_code+','+flight_timestamp+','+address_airline+'">' + flight_code + '</option>');
                        $select_oracle.appendTo('#div_submit_oracles');
                        $('#div_submit_oracles').show();
                    }

                }else{
                    alert("Please, fill all empty spaces in Registration Flight Section!");
                }
            }
        });

         //Buy Insuree.
         DOM.elid('submit_buy_insure').addEventListener('click', () => {

            let address_airline = DOM.elid('buy_insure_airlines');
            let address_client = DOM.elid('buy_client_address').value;
            let flight_code = DOM.elid('options_to_buy_insure');
            let value = DOM.elid('buy_value').value;
            let timestamp = new Date("2020-06-09T12:00:00Z").getTime();

            if(flight_code == null){
                alert("There isn't register flight!");

            }else{

                address_airline = DOM.elid('buy_insure_airlines').value;
                flight_code = DOM.elid('options_to_buy_insure').value;
            
                if(address_airline != '' && address_client != '' && flight_code != '' && value != '' && timestamp != ''){
                    contract.buy(address_airline, flight_code, timestamp, value, address_client, (error, result) => {
                        display('Buy Insuree Done', 'User '+address_client+' buy a insure for a flight: '+flight_code, [ { label: 'Registration:', error: error,  value: 'Success - Insuree purchased' } ]);
                    
                        if(result){
                            let select_ok = DOM.elid('options_to_claim_withdraw');
    
                            if(select_ok != null){
                                $('#options_to_claim_withdraw').append('<option value="'+flight_code+','+timestamp+','+address_airline+'">' + flight_code + '</option>');
                                $('#div_claim_w_flight_code').show();

                                /*$('#options_to_ckeck_balance').append('<option value="'+address_client+'">' + address_client + '</option>');
                                $('#div_user_balance').show();*/
                            }else{
          
                                var $select_claim_w = $('<select/>', {
                                    'class':"form-select",
                                    'id':'options_to_claim_w'
                                });
                                $select_claim_w.append('<option value="'+flight_code+','+timestamp+','+address_airline+'">' + flight_code + '</option>');
                                $select_claim_w.appendTo('#div_claim_w_flight_code');
                                $('#div_claim_w_flight_code').show();

                                /*var $select_check_balance = $('<select/>', {
                                    'class':"form-select",
                                    'id':'options_to_ckeck_balance'
                                });
                                $select_check_balance.append('<option value="'+address_client+'">' + address_client + '</option>');
                                $select_check_balance.appendTo('#div_user_balance');
                                $('#div_user_balance').show();*/
                            }
                        }
                    });
                }else{
                    alert("Please, fill all empty spaces in Buy Insuree Section!");
                }
            }
         });

        DOM.elid('check_balance').addEventListener('click', () => {
            let client_address =  DOM.elid('balance_client_address').value;
            console.log("client_address:", client_address);
            if(client_address != ''){
                contract.getBalance(client_address, (error, result) => {
                    $("#user_balance_label").text(result);
                });
                
            }else{
                alert("Please, fill space empty to check the balance of client!");
            }
           
        });

        DOM.elid('submit_know_value').addEventListener('click', () => {
            let address_client = DOM.elid('claim_w_client_address').value;
            let flight_code_timestamp = DOM.elid('options_to_claim_w');
            let flight_code = "";
            let timestamp = "";
            let airline_adress = "";

            if(flight_code_timestamp == null){
                alert("Theres is no flight insured!"); 

            }else{

                if(address_client != ''){
                    flight_code_timestamp = DOM.elid('options_to_claim_w').value;
                    flight_code_timestamp = flight_code_timestamp.split(",");
                    flight_code = flight_code_timestamp[0];
                    timestamp = flight_code_timestamp[1];
                    airline_adress = flight_code_timestamp[2];

                    contract.getInsuredDue(airline_adress, flight_code, timestamp, address_client, (error, result) => {
                        let value = new BigNumber(result);
                        console.log(result+','+value);
                        $("#user_withdraw_label").text(value);
                    });
                }else{
                    alert("Please, fill the client address in Claim Withdraw section!"); 
                }
                
            }

        });

        
        DOM.elid('submit_claim_withdraw').addEventListener('click', () => {
            let address_client = DOM.elid('claim_w_client_address').value;
            let flight_code_timestamp = DOM.elid('options_to_claim_w');
            let flight_code = "";
            let timestamp = "";
            let airline_adress = "";

            if(flight_code_timestamp == null){
                alert("Theres is no flight insured!"); 

            }else{

                if(address_client != ''){
                    flight_code_timestamp = DOM.elid('options_to_claim_w').value;
                    flight_code_timestamp = flight_code_timestamp.split(",");
                    flight_code = flight_code_timestamp[0];
                    timestamp = flight_code_timestamp[1];
                    airline_adress = flight_code_timestamp[2];
                    contract.withdraw(airline_adress, flight_code, timestamp, address_client, (error, result) => {
                        display('Claim Withdraw', 'User '+address_client, [ { label: 'Registration:', error: error,  value: 'Success - Withdraw paid' } ]);
                    });
                }else{
                    alert("Please, fill the client address in Claim Withdraw section!"); 
                }
                
            }
         });


        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight_code').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h5(title));
    section.appendChild(DOM.div(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}








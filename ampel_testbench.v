`timescale 100ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
//
// Ampel testbench
// IES Lab, TU Darmstadt, 2021
//
//////////////////////////////////////////////////////////////////////////////////
module ampel_testbench;

	reg clk;
	reg reset;

	reg ns_f_an;
	reg hs_f_an;
	
	wire ready;
	wire [4:0] count;   
	   

	wire hs_rt;
	wire hs_ge;
	wire hs_gr;

	wire ns_rt;
 	wire ns_ge;
	wire ns_gr;

	wire hs_f_sg;
	wire hs_f_rt;
	wire hs_f_gr;

	wire ns_f_sg;
	wire ns_f_rt;
	wire ns_f_gr;
	
	wire [4:0] init;
	wire load;

    // The counter used for main for loop.
	integer k; 
	integer i;

    // The maximal wait time for the next transition.
    // If the current state don't reach desired transition after wait_count then throw an error.
	integer wait_count;

    // Save the last state.
	reg[35*8:0] pre_state;

    // Instantiate ampel_sp design under test.
	ampel_sp dut(.clk(clk),
		     .reset(reset), 
		     .ns_f_an(ns_f_an), 
		     .hs_f_an(hs_f_an),
		     .ready(ready),
		     .count(count),
		     .hs_rt(hs_rt), 
		     .hs_ge(hs_ge), 
		     .hs_gr(hs_gr), 
	 	     .ns_rt(ns_rt),
		     .ns_ge(ns_ge),
		     .ns_gr(ns_gr),
		     .hs_f_sg(hs_f_sg),
		     .hs_f_rt(hs_f_rt),
		     .hs_f_gr(hs_f_gr),
		     .ns_f_sg(ns_f_sg),
		     .ns_f_rt(ns_f_rt),
		     .ns_f_gr(ns_f_gr),
		     .init(init),
		     .load(load)
	);

    // Instantiate timer used for the ampel
	timer ampel_timer(.clk(clk),
			  .reset(reset),
			  .init(init),
			  .load(load),
			  .ready(ready),
			  .Q(count)
	);

initial begin
  $dumpfile("dump.vcd");
  $dumpvars(1);
end

// Assert task to verify if the current signal is equal to the desired one.
// If there is a mismatch, debug information such as current state,
// last state, signal name, expected value and some hints are printed 
// on the console window.
task Assert;
	input [4:0] test; 
	input [4:0] desired;
	input reg[35*8:0] state;
	input reg[7*8:0] signal_name;

	begin
		if( test !== desired ) begin
			$display("Fehler im Zustand:%s", state);
			$display("Signal %s ist %d != %d", signal_name, test, desired);
			$display("-------------------------------Hinweise-------------------------------");
			$display("Bitte ueberpruefen Sie, ob Sie die richtige Ausgabe eingestellt haben."); 
			$display("Vorheriger Zustand, der den Test besteht:%s", pre_state);
			$display("Ueberpruefen Sie ab besteheden Zustand, ob Sie:");
			$display("- Das richtige load Signal eingestellt haben.");
			$display("- Den richtige init Wert eingestellt haben.");
			$display("- Ihr Programm korrekt auf dem naechsten Zustand eingestellt wurde.");			
			$finish;
		end 
	end 
endtask


// Task to print current value of all signals.
// Can be used for debuging.
task signal_print;
	begin
		$display("------------Signal------------");
		$display("hs_rt %d ", hs_rt);
		$display("hs_ge %d ", hs_ge); 
		$display("hs_gr %d ", hs_gr);
		$display("ns_rt %d ", ns_rt);	
		$display("ns_ge %d ", ns_ge);
		$display("ns_gr %d ", ns_gr); 
		$display("hs_f_sg %d ", hs_f_sg);
		$display("hs_f_rt %d ", hs_f_rt);	
		$display("hs_f_gr %d ", hs_f_gr);
		$display("ns_f_sg %d ", ns_f_sg); 
		$display("ns_f_rt %d ", ns_f_rt);
		$display("ns_f_gr %d ", ns_f_gr);	
		$display("load %d ", load);
		$display("init %d ", init);
		$display("ready %d ", ready);
		$display("count %d ", count);
		
	end
endtask 

// Task to check state Nebenstrasse Gruen.
// The next state could be NS_G_SHORT, NS_G_SG or NS_Y_SETUP.
task NS_G_check;
    // Check the case jump to NS_G_SHORT
    if(ns_f_an == 1 && count > 5) begin
	while(load == 0) begin
		#2
		if(count == 0) begin
			$display("Timer fuer Nebenstrasse Gruen Signal Kommt ist nicht eingestellt, wenn Q groesser als 5 ist.");
			$finish;
		end
	end
	if(load != 0) begin
		Assert(init, 5, "Nebenstrasse Gruen Verkuerzt Setup", "init");
	end
			
        while(ready != 1) begin
        #2 
        Assert(hs_rt, 1, "Nebenstrasse Gruen Signal Kommt", "hs_rt"); 
        Assert(hs_ge, 0, "Nebenstrasse Gruen Signal Kommt", "hs_ge");
        Assert(hs_gr, 0, "Nebenstrasse Gruen Signal Kommt", "hs_gr");
        Assert(ns_rt, 0, "Nebenstrasse Gruen Signal Kommt", "ns_rt"); 
        Assert(ns_ge, 0, "Nebenstrasse Gruen Signal Kommt", "ns_ge");
        Assert(ns_gr, 1, "Nebenstrasse Gruen Signal Kommt", "ns_gr");
        Assert(hs_f_sg, 0, "Nebenstrasse Gruen Signal Kommt", "hs_f_sg"); 
        Assert(hs_f_rt, 0, "Nebenstrasse Gruen Signal Kommt", "hs_f_rt");
        Assert(hs_f_gr, 1, "Nebenstrasse Gruen Signal Kommt", "hs_f_gr");
        Assert(ns_f_sg, 1, "Nebenstrasse Gruen Signal Kommt", "ns_f_sg"); 
        Assert(ns_f_rt, 1, "Nebenstrasse Gruen Signal Kommt", "ns_f_rt");
        Assert(ns_f_gr, 0, "Nebenstrasse Gruen Signal Kommt", "ns_f_gr");
		Assert(load, 0, "Nebenstrasse Gruen Signal Kommt", "load");
		Assert(init, 0, "Nebenstrasse Gruen Signal Kommt", "init");
        end
		pre_state = 0;
		pre_state = "Nebenstrasse Gruen Signal Kommt"; 
    end
    // Check the case jumps to NS_G_SG
    else if( ns_f_an == 1 && count <= 5) begin
	while(wait_count != 10) begin
		#2 
		wait_count = wait_count + 1;
		if(load != 0 && count != 5) begin
			$display("Fehler im Zustand Nebenstrasse Gruen Signal Kommt.");
			$display("Der Timer-Parameter sollte nicht geaendert werden, wenn Q kleiner als 5 ist.");
			$finish;
		end
	end
	wait_count = 0;

        while(ready != 1) begin
            #2 
            Assert(hs_rt, 1, "Nebenstrasse Gruen Signal Kommt", "hs_rt"); 
        	Assert(hs_ge, 0, "Nebenstrasse Gruen Signal Kommt", "hs_ge");
        	Assert(hs_gr, 0, "Nebenstrasse Gruen Signal Kommt", "hs_gr");
        	Assert(ns_rt, 0, "Nebenstrasse Gruen Signal Kommt", "ns_rt"); 
        	Assert(ns_ge, 0, "Nebenstrasse Gruen Signal Kommt", "ns_ge");
        	Assert(ns_gr, 1, "Nebenstrasse Gruen Signal Kommt", "ns_gr");
        	Assert(hs_f_sg, 0, "Nebenstrasse Gruen Signal Kommt", "hs_f_sg"); 
        	Assert(hs_f_rt, 0, "Nebenstrasse Gruen Signal Kommt", "hs_f_rt");
        	Assert(hs_f_gr, 1, "Nebenstrasse Gruen Signal Kommt", "hs_f_gr");
        	Assert(ns_f_sg, 1, "Nebenstrasse Gruen Signal Kommt", "ns_f_sg"); 
        	Assert(ns_f_rt, 1, "Nebenstrasse Gruen Signal Kommt", "ns_f_rt");
        	Assert(ns_f_gr, 0, "Nebenstrasse Gruen Signal Kommt", "ns_f_gr");	
			Assert(load, 0, "Nebenstrasse Gruen Signal Kommt", "load");
			Assert(init, 0, "Nebenstrasse Gruen Signal Kommt", "init");
        end
	pre_state = 0;
	pre_state = "Nebenstrasse Gruen Signal Kommt";
    end
    // Check the case jumps to NS_Y_SETUP
    else begin
        #2 
    	Assert(hs_rt, 1, "Nebenstrasse Gruen", "hs_rt"); 
        Assert(hs_ge, 0, "Nebenstrasse Gruen", "hs_ge");
        Assert(hs_gr, 0, "Nebenstrasse Gruen", "hs_gr");
        Assert(ns_rt, 0, "Nebenstrasse Gruen", "ns_rt"); 
        Assert(ns_ge, 0, "Nebenstrasse Gruen", "ns_ge");
        Assert(ns_gr, 1, "Nebenstrasse Gruen", "ns_gr");
        Assert(hs_f_sg, 0, "Nebenstrasse Gruen", "hs_f_sg"); 
        Assert(hs_f_rt, 0, "Nebenstrasse Gruen", "hs_f_rt");
        Assert(hs_f_gr, 1, "Nebenstrasse Gruen", "hs_f_gr");
        Assert(ns_f_sg, 0, "Nebenstrasse Gruen", "ns_f_sg"); 
        Assert(ns_f_rt, 1, "Nebenstrasse Gruen", "ns_f_rt");
        Assert(ns_f_gr, 0, "Nebenstrasse Gruen", "ns_f_gr");
		Assert(load, 0, "Nebenstrasse Gruen", "load");
		Assert(init, 0, "Nebenstrasse Gruen", "init");

    end
endtask

// Task to check Hauptstrasse Gruen state.
// The next task could be HS_G_SHORT, HS_G_SG, HS_Y_SETUP
task HS_G_check;
    // Check the case jumps to HS_G_SHORT
    if(hs_f_an == 1 && count > 5) begin
	while(load == 0) begin
		#2
		if(count == 0) begin
			$display("Timer fuer Hauptstrasse Gruen Signal Kommt ist nicht eingestellt, wenn Q groesser als 5 ist.");
			$finish;
		end
	end
	if(load != 0) begin
		Assert(init, 5, "Hauptstrasse Gruen Verkuerzt Setup", "init");
	end
	
        while(ready != 1) begin
        #2 
      	Assert(hs_rt, 0, "Hauptstrasse Gruen Signal Kommt", "hs_rt"); 
        Assert(hs_ge, 0, "Hauptstrasse Gruen Signal Kommt", "hs_ge");
        Assert(hs_gr, 1, "Hauptstrasse Gruen Signal Kommt", "hs_gr");
        Assert(ns_rt, 1, "Hauptstrasse Gruen Signal Kommt", "ns_rt"); 
        Assert(ns_ge, 0, "Hauptstrasse Gruen Signal Kommt", "ns_ge");
        Assert(ns_gr, 0, "Hauptstrasse Gruen Signal Kommt", "ns_gr");
        Assert(hs_f_sg, 1, "Hauptstrasse Gruen Signal Kommt", "hs_f_sg"); 
        Assert(hs_f_rt, 1, "Hauptstrasse Gruen Signal Kommt", "hs_f_rt");
        Assert(hs_f_gr, 0, "Hauptstrasse Gruen Signal Kommt", "hs_f_gr");
        Assert(ns_f_sg, 0, "Hauptstrasse Gruen Signal Kommt", "ns_f_sg"); 
        Assert(ns_f_rt, 0, "Hauptstrasse Gruen Signal Kommt", "ns_f_rt");
        Assert(ns_f_gr, 1, "Hauptstrasse Gruen Signal Kommt", "ns_f_gr");
		Assert(load, 0, "Hauptstrasse Gruen Signal Kommt", "load");
		Assert(init, 0, "Hauptstrasse Gruen Signal Kommt", "init");
        end
		pre_state = 0;
		pre_state = "Hauptstrasse Gruen Signal Kommt";
    end
    // Check the case jumps to HS_G_SG
    else if( hs_f_an == 1 && count <= 5) begin

		while(wait_count != 10) begin
			#2 
			wait_count = wait_count + 1;
			if(load != 0 && count != 5) begin
				$display("Fehler im Zustand Hauptstrasse Gruen Signal Kommt.");
				$display("Der Timer-Parameter sollte nicht geaendert werden, wenn Q kleiner als 5 ist.");
				$finish;
			end
		end
		wait_count = 0;

        while(ready != 1) begin
            #2 
            Assert(hs_rt, 0, "Hauptstrasse Gruen Signal Kommt", "hs_rt"); 
        	Assert(hs_ge, 0, "Hauptstrasse Gruen Signal Kommt", "hs_ge");
        	Assert(hs_gr, 1, "Hauptstrasse Gruen Signal Kommt", "hs_gr");
        	Assert(ns_rt, 1, "Hauptstrasse Gruen Signal Kommt", "ns_rt"); 
        	Assert(ns_ge, 0, "Hauptstrasse Gruen Signal Kommt", "ns_ge");
        	Assert(ns_gr, 0, "Hauptstrasse Gruen Signal Kommt", "ns_gr");
        	Assert(hs_f_sg, 1, "Hauptstrasse Gruen Signal Kommt", "hs_f_sg"); 
        	Assert(hs_f_rt, 1, "Hauptstrasse Gruen Signal Kommt", "hs_f_rt");
        	Assert(hs_f_gr, 0, "Hauptstrasse Gruen Signal Kommt", "hs_f_gr");
        	Assert(ns_f_sg, 0, "Hauptstrasse Gruen Signal Kommt", "ns_f_sg"); 
        	Assert(ns_f_rt, 0, "Hauptstrasse Gruen Signal Kommt", "ns_f_rt");
        	Assert(ns_f_gr, 1, "Hauptstrasse Gruen Signal Kommt", "ns_f_gr");
			Assert(load, 0, "Hauptstrasse Gruen Signal Kommt", "load");
			Assert(init, 0, "Hauptstrasse Gruen Signal Kommt", "init");
        end
	pre_state = 0;
	pre_state = "Hauptstrasse Gruen Signal Kommt";

    end
    // Check the case jumps to HS_Y_SETUP
    else begin
        #2 
		Assert(hs_rt, 0, "Hauptstrasse Gruen", "hs_rt"); 
        Assert(hs_ge, 0, "Hauptstrasse Gruen", "hs_ge");
        Assert(hs_gr, 1, "Hauptstrasse Gruen", "hs_gr");
        Assert(ns_rt, 1, "Hauptstrasse Gruen", "ns_rt"); 
        Assert(ns_ge, 0, "Hauptstrasse Gruen", "ns_ge");
        Assert(ns_gr, 0, "Hauptstrasse Gruen", "ns_gr");
        Assert(hs_f_sg, 0, "Hauptstrasse Gruen", "hs_f_sg"); 
        Assert(hs_f_rt, 1, "Hauptstrasse Gruen", "hs_f_rt");
        Assert(hs_f_gr, 0, "Hauptstrasse Gruen", "hs_f_gr");
        Assert(ns_f_sg, 0, "Hauptstrasse Gruen", "ns_f_sg"); 
        Assert(ns_f_rt, 0, "Hauptstrasse Gruen", "ns_f_rt");
        Assert(ns_f_gr, 1, "Hauptstrasse Gruen", "ns_f_gr");
		Assert(load, 0, "Hauptstrasse Gruen", "load");
		Assert(init, 0, "Hauptstrasse Gruen", "init");
    end
endtask

// At state Nebenstrasse Gruen, the light will count down for 15 time units.
// The signal ns_f_an could be turn on at anytime in this period.
// This task turn on the signal ns_f_an at input time (second) unit and verify
// if the behavior of the design is correct. 
task ns_f_an_case;
	input integer second;
	begin
		while(count > 15 - second) begin NS_G_check(); end
		pre_state = 0;
		pre_state = "Nebenstrasse Gruen";
		
		ns_f_an = 1;
		while(ready != 1) begin NS_G_check(); end
		ns_f_an = 0;
	
	end 
endtask

// At state Hauptstrasse Gruen, the light will count down for 15 time units.
// The signal hs_f_an could be turn on at anytime in this period.
// This task turn on the signal hs_f_an at input time (second) and verify
// if the behavior of the design is correct.
task hs_f_an_case;
	input integer second;
	begin
		while(count > 15 - second) begin HS_G_check(); end
		pre_state = 0;
		pre_state = "Hauptstrasse Gruen";
		hs_f_an = 1;
		while(ready != 1) begin HS_G_check(); end
		hs_f_an = 0;
	end 
endtask


// Task to turn on hs_f_an at each time in 15 time unit period
// and verify the result.
task hs_f_an_test;
	input integer second;
	case(second)
	0: while(ready != 1) begin HS_G_check();end
	1: hs_f_an_case(0);
	2: hs_f_an_case(1);
	3: hs_f_an_case(2);
	4: hs_f_an_case(3);
	5: hs_f_an_case(4);
	6: hs_f_an_case(5);
	7: hs_f_an_case(6);
	8: hs_f_an_case(7);
	9: hs_f_an_case(8);
	10: hs_f_an_case(9);
	11: hs_f_an_case(10);
	12: hs_f_an_case(11);
	13: hs_f_an_case(12);
	14: hs_f_an_case(13);
	15: hs_f_an_case(14);
	endcase 
endtask

// Task to turn on hs_f_an at each time in 15 time unit period
// and verify the result.
task ns_f_an_test;
	input integer second;
	case(second)
	0: while(ready != 1) begin NS_G_check();end
	1: ns_f_an_case(0);
	2: ns_f_an_case(1);
	3: ns_f_an_case(2);
	4: ns_f_an_case(3);
	5: ns_f_an_case(4);
	6: ns_f_an_case(5);
	7: ns_f_an_case(6);
	8: ns_f_an_case(7);
	9: ns_f_an_case(8);
	10: ns_f_an_case(9);
	11: ns_f_an_case(10);
	12: ns_f_an_case(11);
	13: ns_f_an_case(12);
	14: ns_f_an_case(13);
	15: ns_f_an_case(14);
	endcase 
endtask

// Task to display the test case information on the console. 
task test_info;
	input integer second;
	case(second)
	0: begin 
		$display("Testfall 0 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 0 und hs_f_an = 0");
	end
	1: begin 
		$display("Testfall 1 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 15. Sekunde der gruenen Zustaende.");
	end
	2: begin 
		$display("Testfall 2 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 14. Sekunde der gruenen Zustaende.");
	end
	3: begin 
		$display("Testfall 3 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 13. Sekunde der gruenen Zustaende.");
	end
	4: begin 
		$display("Testfall 4 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 12. Sekunde der gruenen Zustaende.");
	end
	5: begin 
		$display("Testfall 5 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 11. Sekunde der gruenen Zustaende.");
	end
	6: begin 
		$display("Testfall 6 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 10. Sekunde der gruenen Zustaende.");
	end
	7: begin 
		$display("Testfall 7 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 9. Sekunde der gruenen Zustaende.");
	end
	8: begin 
		$display("Testfall 8 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 8. Sekunde der gruenen Zustaende.");
	end
	9: begin 
		$display("Testfall 9 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 7. Sekunde der gruenen Zustaende.");
	end
	10: begin 
		$display("Testfall 10 ausfuehren:");
		$display(" Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 6. Sekunde der gruenen Zustaende.");
	end
	11: begin 
		$display("Testfall 11 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 5. Sekunde der gruenen Zustaende.");
	end
	12: begin 
		$display("Testfall 12 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 4. Sekunde der gruenen Zustaende.");
	end
	13: begin 
		$display("Testfall 13 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 3. Sekunde der gruenen Zustaende.");
	end
	14: begin 
		$display("Testfall 14 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 2. Sekunde der gruenen Zustaende.");
	end
	15: begin 
		$display("Testfall 15 ausfuehren:");
		$display("Testen die Ampel mit ns_f_an = 1 und hs_f_an = 1 in der 1. Sekunde der gruenen Zustaende.");
	end
	endcase
endtask

// Task to display the passed test cases.
task test_passed;
	input integer second;
	case(second)
	0: $display("Testfall 0 bestehen!");
	1: $display("Testfall 1 bestehen!");
	2: $display("Testfall 2 bestehen!");
	3: $display("Testfall 3 bestehen!");
	4: $display("Testfall 4 bestehen!");
	5: $display("Testfall 5 bestehen!");
	6: $display("Testfall 6 bestehen!");
	7: $display("Testfall 7 bestehen!");
	8: $display("Testfall 8 bestehen!");
	9: $display("Testfall 9 bestehen!");
	10: $display("Testfall 10 bestehen!");
	11: $display("Testfall 11 bestehen!");
	12: $display("Testfall 12 bestehen!");
	13: $display("Testfall 13 bestehen!");
	14: $display("Testfall 14 bestehen!");
	15: $display("Testfall 15 bestehen!");
	endcase
endtask

// At each state, the testbench will wait for a wait_count time
// and expect the transition to the next state in this period of time.
// If there is no transition in this period, the waiting loop will break 
// and throw an error. There could be an error in the design which 
// make the finite state machine stuck and cannot move to the next one.
task loop_break;
	input reg[35*8:0] state;
	begin
	wait_count = wait_count + 1;
	if(wait_count == 200) begin
		$display("Fehler im Zustand:%s", state);
		$display("-------------------------------Hinweise-------------------------------");
		$display("Vorheriger Zustand, der den Test besteht:%s", pre_state);
		$display("Ueberpruefen Sie ab besteheden Zustand, ob Sie ihr Programm korrekt auf dem n�chsten Zustand eingestellt wurde.");
		$finish;
	end
	end
endtask

// Init the variables
initial begin
	clk = 0;
	reset = 0;
	ns_f_an = 0;
	hs_f_an = 0;
	wait_count = 0;
	pre_state = "Reset State";
end 

// Clock generator.
always begin
	#1 clk =~clk;
end

// This is the main block of the testbench that includes a for loop 
// and generates 16 test cases. The first case checks the FSM without 
// the effect of ns_f_an and hs_f_an signals. The other 15 cases turn 
// these two signals at different time slots to verify the behavior 
// of the design.
initial begin
	#1 reset = 1;
	#1 reset = 0;
	// Check the reset state.
	if(load == 0 || init !== 1) begin
		$display("Der Timer sollte im Zustand Hauptstrasse Nebenstrasse Rot Setup (reset Zustand) auf 1 eingestellt sein");
		$finish;
	end 	
	#1
// Main for loop generates test cases. 
for( k = 0; k <= 15; k = k + 1) begin 
	// Print the current test information.
	test_info(k);
	// When the ready signal is set to 1, the output is verified.
	// Throw an error when test case is fail, otherwise, save the 
	// current state to pre_state and move to the next one.
	while(ready != 1) begin 
		#2 
		Assert(hs_rt, 1, "Hauptstrasse Nebenstrasse Rot", "hs_rt"); 
		Assert(hs_ge, 0, "Hauptstrasse Nebenstrasse Rot", "hs_ge");
		Assert(hs_gr, 0, "Hauptstrasse Nebenstrasse Rot", "hs_gr");
		Assert(ns_rt, 1, "Hauptstrasse Nebenstrasse Rot", "ns_rt"); 
		Assert(ns_ge, 0, "Hauptstrasse Nebenstrasse Rot", "ns_ge");
		Assert(ns_gr, 0, "Hauptstrasse Nebenstrasse Rot", "ns_gr");
		Assert(hs_f_sg, 0, "Hauptstrasse Nebenstrasse Rot", "hs_f_sg"); 
		Assert(hs_f_rt, 1, "Hauptstrasse Nebenstrasse Rot", "hs_f_rt");
		Assert(hs_f_gr, 0, "Hauptstrasse Nebenstrasse Rot", "hs_f_gr");
		Assert(ns_f_sg, 0, "Hauptstrasse Nebenstrasse Rot", "ns_f_sg"); 
		Assert(ns_f_rt, 1, "Hauptstrasse Nebenstrasse Rot", "ns_f_rt");
		Assert(ns_f_gr, 0, "Hauptstrasse Nebenstrasse Rot", "ns_f_gr");
		Assert(load, 0, "Hauptstrasse Nebenstrasse Rot", "load");
		Assert(init, 0, "Hauptstrasse Nebenstrasse Rot", "init");
	end
	pre_state = 0;
	pre_state = "Hauptstrasse Nebenstrasse Rot";

	// Wait for the transition to the next state.
	// If there is no transition in a predefined time, 
	// throw an error, otherwise, reset the wait_count 
	// to 0 for the next time.
	while(ready == 1 || load != 0) begin
	#2	loop_break("Hauptstrasse Rot Gelb Setup");
		if(load != 0) begin
			Assert(init, 1, "Hauptstrasse Rot Gelb Setup", "init");
		end
	end
	wait_count = 0;

	while (ready != 1) begin
		#2 
		Assert(hs_rt, 1, "Hauptstrasse Rot Gelb", "hs_rt"); 
		Assert(hs_ge, 1, "Hauptstrasse Rot Gelb", "hs_ge");
		Assert(hs_gr, 0, "Hauptstrasse Rot Gelb", "hs_gr");
		Assert(ns_rt, 1, "Hauptstrasse Rot Gelb", "ns_rt"); 
		Assert(ns_ge, 0, "Hauptstrasse Rot Gelb", "ns_ge");
		Assert(ns_gr, 0, "Hauptstrasse Rot Gelb", "ns_gr");
		Assert(hs_f_sg, 0, "Hauptstrasse Rot Gelb", "hs_f_sg"); 
		Assert(hs_f_rt, 1, "Hauptstrasse Rot Gelb", "hs_f_rt");
		Assert(hs_f_gr, 0, "Hauptstrasse Rot Gelb", "hs_f_gr");
		Assert(ns_f_sg, 0, "Hauptstrasse Rot Gelb", "ns_f_sg"); 
		Assert(ns_f_rt, 1, "Hauptstrasse Rot Gelb", "ns_f_rt");
		Assert(ns_f_gr, 0, "Hauptstrasse Rot Gelb", "ns_f_gr");
		Assert(load, 0, "Hauptstrasse Rot Gelb", "load");
		Assert(init, 0, "Hauptstrasse Rot Gelb", "init");
	end
	pre_state = 0;
	pre_state = "Hauptstrasse Rot Gelb"; 
	
	while(ready == 1 || load != 0) begin
	#2 	loop_break("Hauptstrasse Gruen Setup");
		if(load != 0) begin
			Assert(init, 15, "Hauptstrasse Gruen Setup", "init");
		end
	end
	wait_count = 0;

	#2 $display("Testen das hs_f_an signal...");
	//Check Hauptstrasse Gruen with ns_f_an signal
	hs_f_an_test(k);

	while(ready == 1 || load != 0) begin
	#2	loop_break("Hauptstrasse Gelb Setup"); 
		if(load != 0) begin
			Assert(init, 1, "Hauptstrasse Gelb Setup", "init");
		end
	end
	wait_count = 0;

	while(ready != 1) begin
		#2 
		Assert(hs_rt, 0, "Hauptstrasse Gelb", "hs_rt"); 
		Assert(hs_ge, 1, "Hauptstrasse Gelb", "hs_ge");
		Assert(hs_gr, 0, "Hauptstrasse Gelb", "hs_gr");
		Assert(ns_rt, 1, "Hauptstrasse Gelb", "ns_rt"); 
		Assert(ns_ge, 0, "Hauptstrasse Gelb", "ns_ge");
		Assert(ns_gr, 0, "Hauptstrasse Gelb", "ns_gr");
		Assert(hs_f_sg, 0, "Hauptstrasse Gelb", "hs_f_sg"); 
		Assert(hs_f_rt, 1, "Hauptstrasse Gelb", "hs_f_rt");
		Assert(hs_f_gr, 0, "Hauptstrasse Gelb", "hs_f_gr");
		Assert(ns_f_sg, 0, "Hauptstrasse Gelb", "ns_f_sg"); 
		Assert(ns_f_rt, 1, "Hauptstrasse Gelb", "ns_f_rt");
		Assert(ns_f_gr, 0, "Hauptstrasse Gelb", "ns_f_gr");
		Assert(load, 0, "Hauptstrasse Gelb", "load");
		Assert(init, 0, "Hauptstrasse Gelb", "init");
	end
	pre_state = 0;
	pre_state = "Hauptstrasse Gelb";  
	
	while(ready == 1 || load != 0) begin
	#2	loop_break("Nebenstrasse Hauptstrasse Rot Setup"); 
		if(load != 0) begin
			Assert(init, 1, "Nebenstrasse Hauptstrasse Rot Setup", "init");
		end
	end
	wait_count = 0;

	while(ready != 1) begin
		#2 
		Assert(hs_rt, 1, "Nebenstrasse Hauptstrasse Rot", "hs_rt"); 
		Assert(hs_ge, 0, "Nebenstrasse Hauptstrasse Rot", "hs_ge");
		Assert(hs_gr, 0, "Nebenstrasse Hauptstrasse Rot", "hs_gr");
		Assert(ns_rt, 1, "Nebenstrasse Hauptstrasse Rot", "ns_rt"); 
		Assert(ns_ge, 0, "Nebenstrasse Hauptstrasse Rot", "ns_ge");
		Assert(ns_gr, 0, "Nebenstrasse Hauptstrasse Rot", "ns_gr");
		Assert(hs_f_sg, 0, "Nebenstrasse Hauptstrasse Rot", "hs_f_sg"); 
		Assert(hs_f_rt, 1, "Nebenstrasse Hauptstrasse Rot", "hs_f_rt");
		Assert(hs_f_gr, 0, "Nebenstrasse Hauptstrasse Rot", "hs_f_gr");
		Assert(ns_f_sg, 0, "Nebenstrasse Hauptstrasse Rot", "ns_f_sg"); 
		Assert(ns_f_rt, 1, "Nebenstrasse Hauptstrasse Rot", "ns_f_rt");
		Assert(ns_f_gr, 0, "Nebenstrasse Hauptstrasse Rot", "ns_f_gr");
		Assert(load, 0, "Nebenstrasse Hauptstrasse Rot", "load");
		Assert(init, 0, "Nebenstrasse Hauptstrasse Rot", "init");
	end
	pre_state = 0;
	pre_state = "Nebenstrasse Hauptstrasse Rot"; 

	while(ready == 1 || load != 0) begin
	#2	loop_break("Nebenstrasse Hauptstrasse Rot Gelb Setup");
		if(load != 0) begin
			Assert(init, 1, "Nebenstrasse Hauptstrasse Rot Gelb Setup", "init");
		end
	end
	wait_count = 0;

	while(ready != 1) begin
		#2 
		Assert(hs_rt, 1, "Nebenstrasse Rot Gelb", "hs_rt"); 
		Assert(hs_ge, 0, "Nebenstrasse Rot Gelb", "hs_ge");
		Assert(hs_gr, 0, "Nebenstrasse Rot Gelb", "hs_gr");
		Assert(ns_rt, 1, "Nebenstrasse Rot Gelb", "ns_rt"); 
		Assert(ns_ge, 1, "Nebenstrasse Rot Gelb", "ns_ge");
		Assert(ns_gr, 0, "Nebenstrasse Rot Gelb", "ns_gr");
		Assert(hs_f_sg, 0, "Nebenstrasse Rot Gelb", "hs_f_sg"); 
		Assert(hs_f_rt, 1, "Nebenstrasse Rot Gelb", "hs_f_rt");
		Assert(hs_f_gr, 0, "Nebenstrasse Rot Gelb", "hs_f_gr");
		Assert(ns_f_sg, 0, "Nebenstrasse Rot Gelb", "ns_f_sg"); 
		Assert(ns_f_rt, 1, "Nebenstrasse Rot Gelb", "ns_f_rt");
		Assert(ns_f_gr, 0, "Nebenstrasse Rot Gelb", "ns_f_gr");
		Assert(load, 0, "Nebenstrasse Rot Gelb", "load");
		Assert(init, 0, "Nebenstrasse Rot Gelb", "init");	
	end
	pre_state = 0;
	pre_state = "Nebenstrasse Rot Gelb"; 
 
	while(ready == 1 || load != 0) begin
	#2	loop_break( "Nebenstrasse Gruen Setup");
		if(load != 0) begin
			Assert(init, 15, "Nebenstrasse Gruen Setup", "init");
		end
	end
	wait_count = 0;
	
	#2 $display("Testen das ns_f_an Signal..."); 
	ns_f_an_test(k);

	while(ready == 1 || load != 0) begin
	#2	loop_break("Nebenstrasse Gelb Setup");
		if(load != 0) begin
			Assert(init, 1, "Nebenstrasse Gelb Setup", "init");
		end
	end
	wait_count = 0;

	while(ready != 1) begin
		#2 
		Assert(hs_rt, 1, "Nebenstrasse Gelb", "hs_rt"); 
		Assert(hs_ge, 0, "Nebenstrasse Gelb", "hs_ge");
		Assert(hs_gr, 0, "Nebenstrasse Gelb", "hs_gr");
		Assert(ns_rt, 0, "Nebenstrasse Gelb", "ns_rt"); 
		Assert(ns_ge, 1, "Nebenstrasse Gelb", "ns_ge");
		Assert(ns_gr, 0, "Nebenstrasse Gelb", "ns_gr");
		Assert(hs_f_sg, 0, "Nebenstrasse Gelb", "hs_f_sg"); 
		Assert(hs_f_rt, 1, "Nebenstrasse Gelb", "hs_f_rt");
		Assert(hs_f_gr, 0, "Nebenstrasse Gelb", "hs_f_gr");
		Assert(ns_f_sg, 0, "Nebenstrasse Gelb", "ns_f_sg"); 
		Assert(ns_f_rt, 1, "Nebenstrasse Gelb", "ns_f_rt");
		Assert(ns_f_gr, 0, "Nebenstrasse Gelb", "ns_f_gr");
		Assert(load, 0, "Nebenstrasse Gelb", "load");
		Assert(init, 0, "Nebenstrasse Gelb", "init");	
	end
	pre_state = 0;
	pre_state = "Nebenstrasse Gelb"; 
 
	while(ready == 1 || load != 0) begin
	#2	loop_break("Hauptstrasse Nebenstrasse Rot Setup");
		if(load != 0) begin
			Assert(init, 1, "Hauptstrasse Nebenstrasse Rot Setup", "init");
		end
	end
	wait_count = 0;	

	// If the design can reach this state, it passed this test.
	// Print the result on the console window.
	test_passed(k);
	$display("");	 
end
	$display("Alle Tests bestanden");
	#100 $finish;
end 
	
endmodule 

//////////////////////////////////////////////////////////////////////////////////
//
// timer Modul
// Ferdinand Keil, TU Darmstadt, 2018
//
//////////////////////////////////////////////////////////////////////////////////
module timer(
	input  clk,        // Taktsignal (50 MHz)
	input  reset,      // Resetsignal
	input  load,       // Latchsignal (positive Flanke laedt Startwert)
	input  [4:0] init, // Startwert in Sekunden
	output reg ready,  // Ausgangssignal, high wenn Zaehler null erreicht
	output [4:0] Q     // Aktueller Wert des Zaehlers
);

parameter maxcnt = 31'd40; // 1 sec

(* KEEP = "TRUE" *) reg [4:0] sec_cnt;
reg [30:0] cnt;
reg load_last;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		// reset registers to default values after reset
		cnt <= 31'd0;
		sec_cnt <= 5'd0;
		ready <= 1'b0;
		load_last <= 1'b0;
		
	end
	else if (load && ~load_last) begin
		// triggers on posedge of load and latches init value into register
		if (init > 5'd0) begin
			// if init equals zero, timer is not started and output reset
			sec_cnt <= init;
			cnt <= maxcnt;
		end
		ready <= 1'b0;
		load_last <= 1'b1;
	end
	else begin
		// actual trigger functionality
		load_last <= load;
		if (cnt > 31'd0) begin
			cnt <= cnt - 31'd1; // decrement primary counter
			ready <= 1'b0;
		end
		else begin
			if (sec_cnt > 5'd1) begin
				sec_cnt <= sec_cnt - 5'd1; // decrease secondary counter
				cnt <= maxcnt; // restart primary counter
				ready <= 1'b0;
			end
			else begin
				sec_cnt <= 5'd0;
				ready <= 1'b1; // time's up, so we set ready signal
			end
		end
	end
end

assign Q = sec_cnt; // outputs current (secondary) counter value

endmodule

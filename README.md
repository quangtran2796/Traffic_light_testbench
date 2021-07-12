# Traffic_light_testbench

A testbench of traffic light system used for electronic lab.

## Description

A verilog testbench of a traffic light system. The testbench is designed based on the reference finite state machine of the electronic lab TU Darmstadt. 

The testbench provide 16 test cases. The first case verify the finite state machine without the effect of 
ns_f_an and hs_f_an signals. The other cases verify the behavior of the design while turn on these two signals
at different time steps.

ns_f_an and hs_f_an are the signals triggered by the pedestrian when they want to across the street.

## Usage

The design need to test should named as ampel_sp and have the input, output signals the same as the testbench.

The reset state should be set as Hauptstrasse Nebenstrasse Rot Setup.

The task test_info can be used to print the information of the current test case.

The task signal_print can be used to print all the output signals of the design at calling time. This might be useful for debugging.

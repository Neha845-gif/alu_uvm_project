
`include "defines.sv"

interface alu_interface(input logic clk, rst);

    //input signals
    logic [1:0] inp_valid;
    logic mode;
    logic [3:0] cmd;
    logic [`width-1:0] op_a;
    logic [`width-1:0] op_b;
    logic ce;
    logic cin;

    //output signals
    logic [`width:0] res;
    logic g, e, l, err, oflow, cout;

    //clocking block for driver
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output inp_valid, mode, cmd, op_a, op_b, ce, cin;
        input res, g, e, l, err, oflow, cout;
    endclocking

    //clocking block for monitor
    clocking monitor_cb @(posedge clk);
        default input #1 output #1;
        input inp_valid, mode, cmd, op_a, op_b, ce, cin, res, g, e, l, err, oflow, cout;
    endclocking

    modport DRV(clocking driver_cb, input clk, rst);
    modport MON(clocking monitor_cb, input clk, rst);
    modport DUT  (input clk, rst, inp_valid, mode, cmd, op_a, op_b, ce, cin,
              output res, g, e, l, err, oflow, cout);
endinterface

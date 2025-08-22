import uvm_pkg::*;
`include "uvm_macros.svh"
`include "my_interface.sv"
`include "my_pkg.sv"
`include "design.sv"
`include "defines.sv"
import my_pkg::*;
module top;


  bit clk = 0;     // initialize clock
  bit rst;

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1;
    repeat (3) @(posedge clk); // hold reset for 3 cycles
    rst = 0;
  end

  // Interface instantiation
alu_interface intf(clk, rst);

  // DUT instantiation
alu #(`width) dut (
    .CLK      (intf.clk),
    .RST      (intf.rst),
    .INP_VALID(intf.inp_valid),
    .MODE     (intf.mode),
    .CIN      (intf.cin),
    .OPA      (intf.op_a),
    .OPB      (intf.op_b),
    .CE       (intf.ce),
    .CMD      (intf.cmd),
    .RES      (intf.res),
    .COUT     (intf.cout),
    .OFLOW    (intf.oflow),
    .E        (intf.e),
    .L        (intf.l),
    .G        (intf.g),
    .ERR      (intf.err)
);



 // UVM config and dump
  initial begin
    uvm_config_db#(virtual alu_interface)::set(uvm_root::get(), "*", "vif", intf);
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  // Run UVM test
  initial begin
    run_test("my_test");  // UVM ends simulation itself
  end

endmodule

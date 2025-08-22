
`include "defines.sv"
class seq_item extends uvm_sequence_item;

rand bit rst;
rand bit [1:0] inp_valid;
rand bit  mode;
rand bit [3:0] cmd;
rand bit  ce;
rand bit [`width-1:0] op_a;
rand bit [`width-1:0] op_b;
rand bit cin;

rand bit err;
rand bit g;
rand bit e;
rand bit l;
rand bit cout;
rand bit [`width:0] res;
rand bit oflow;

`uvm_object_utils_begin(seq_item)
`uvm_field_int(rst, UVM_ALL_ON)
`uvm_field_int(inp_valid, UVM_ALL_ON)
`uvm_field_int(mode, UVM_ALL_ON)
`uvm_field_int(cmd, UVM_ALL_ON)
`uvm_field_int(ce, UVM_ALL_ON)
`uvm_field_int(op_a, UVM_ALL_ON)
`uvm_field_int(op_b, UVM_ALL_ON)
`uvm_field_int(cin, UVM_ALL_ON)
`uvm_field_int(cout, UVM_ALL_ON)
`uvm_field_int(err, UVM_ALL_ON)
`uvm_field_int(g, UVM_ALL_ON)
`uvm_field_int(l, UVM_ALL_ON)
`uvm_field_int(e, UVM_ALL_ON)
`uvm_field_int(res, UVM_ALL_ON)
`uvm_field_int(oflow, UVM_ALL_ON)
`uvm_object_utils_end


function new(string name = "sequence_item");
super.new(name);
endfunction

function void copy_inputs(seq_item rhs);
  this.inp_valid = rhs.inp_valid;
  this.mode      = rhs.mode;
  this.cmd       = rhs.cmd;
  this.ce        = rhs.ce;
  this.op_a      = rhs.op_a;
  this.op_b      = rhs.op_b;
  this.cin       = rhs.cin;

  this.res   = 0;
  this.e     = 0;
  this.g     = 0;
  this.l     = 0;
  this.oflow = 0;
  this.cout  = 0;
  this.err   = 0;
endfunction


constraint ce_cons  { ce == 1; }
constraint rst_cons { rst == 0; }
constraint inp_valid_cons { inp_valid inside {[0:3]}; }
constraint inp_valid_case { inp_valid!= 2'b00; }
constraint mode_a { mode inside {0,1}; }
constraint cmd_a {(mode == 1) -> cmd inside {[0:10]};}
constraint cmd_b {(mode == 0) -> cmd inside {[0:13]};}

endclass

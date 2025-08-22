
// ==========================================================
// File: my_sequence.sv
// Corrected UVM sequences for QuestaSim compilation
// ==========================================================

class my_sequence extends uvm_sequence#(seq_item);
  `uvm_object_utils(my_sequence)

  function new(string name = "my_sequence");
    super.new(name);
  endfunction

  task body();
    seq_item req;
    for(int i = 0; i < `no_of_transactions; i++) begin
      req = seq_item::type_id::create($sformatf("req[%0d]", i));
      wait_for_grant();
      assert(req.randomize());
      send_request(req);
      wait_for_item_done();
    end
    `uvm_info(get_type_name(), "@@@@@@@@@@@@@@@@@@@ sent all transactions @@@@@@@@@@@@@@@@@@@@", UVM_LOW);
  endtask
endclass


// ----------------------------------------------------------
// my_sequence1
// ----------------------------------------------------------
class my_sequence1 extends uvm_sequence#(seq_item);
  `uvm_object_utils(my_sequence1)

  function new(string name = "my_sequence1");
    super.new(name);
  endfunction

  virtual task body();
    seq_item req;

    req = seq_item::type_id::create("req1");
    `uvm_do_with(req, {mode == 0; cmd == 4; })
   req.print();
  endtask
endclass


// ----------------------------------------------------------
// my_sequence2
// ----------------------------------------------------------
class my_sequence2 extends uvm_sequence#(seq_item);
  `uvm_object_utils(my_sequence2)

  function new(string name = "my_sequence2");
    super.new(name);
  endfunction

  virtual task body();
    seq_item req;

    req = seq_item::type_id::create("req1");
    `uvm_do_with(req, { mode == 1; cmd == 0; inp_valid != 2'b11; })
    req.print();
  endtask
endclass


// ----------------------------------------------------------
// my_sequence3
// ----------------------------------------------------------
class my_sequence3 extends uvm_sequence#(seq_item);
  `uvm_object_utils(my_sequence3)

  function new(string name = "my_sequence3");
    super.new(name);
  endfunction

  virtual task body();
    seq_item req;

    req = seq_item::type_id::create("req1");
    `uvm_do_with(req, { op_b == 8'b00010000; })

    req = seq_item::type_id::create("req2");
    `uvm_do_with(req, { op_b == 8'b01000000; })

    req = seq_item::type_id::create("req3");
    `uvm_do_with(req, { op_b == 8'b00100000; })

    req = seq_item::type_id::create("req4");
    `uvm_do_with(req, { op_b == 8'b10000000; })

    req = seq_item::type_id::create("req5");
    `uvm_do_with(req, { op_a==0; op_b!=0; inp_valid == 2'b10; })

    req = seq_item::type_id::create("req6");
    `uvm_do_with(req, { op_a!=0; op_b==0; inp_valid == 2'b01; })

    req = seq_item::type_id::create("req7");
    `uvm_do_with(req, { op_a!=0; op_b!=0; inp_valid == 2'b11; })


  endtask
endclass


// ----------------------------------------------------------
// my_regression
// ----------------------------------------------------------
class my_regression extends uvm_sequence#(seq_item);
  `uvm_object_utils(my_regression)

  my_sequence1 m1;
  my_sequence2 m2;
  my_sequence3 m3;
  // my_sequence4 m4; // Uncomment if you create sequence4

  function new(string name = "my_regression");
    super.new(name);
  endfunction

  virtual task body();
    m1 = my_sequence1::type_id::create("m1");
    m2 = my_sequence2::type_id::create("m2");
    m3 = my_sequence3::type_id::create("m3");

    `uvm_do(m1)
    `uvm_do(m2)
    `uvm_do(m3)
    // `uvm_do(m4)
  endtask
endclass

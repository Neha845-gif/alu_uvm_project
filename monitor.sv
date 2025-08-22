
`include "defines.sv"
class my_driver extends uvm_driver#(seq_item);

  virtual alu_interface  vif;

  bit [3:0] cmd_fixed;
  bit ce_fixed;
  bit mode_fixed;

  uvm_analysis_port#(seq_item)item_collect_port;

  `uvm_component_utils(my_driver)

  function new(string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
    item_collect_port = new("item_collect_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_interface)::get(this, "", "vif", vif))
      `uvm_error(get_type_name(), "Failed to get interface signals")
    else
      `uvm_info(get_type_name(), "Got the interface signals", UVM_NONE);
  endfunction

  virtual task run_phase(uvm_phase phase);
    seq_item drv_trans;
    forever begin
      seq_item_port.get_next_item(drv_trans);
      drive(drv_trans);
      item_collect_port.write(drv_trans);
      seq_item_port.item_done();
    end
  endtask

  task drive(seq_item drv_trans);
    // Store fixed values
    cmd_fixed = drv_trans.cmd;
    ce_fixed = drv_trans.ce;
    mode_fixed = drv_trans.mode;

    for(int i = 0; i < `no_of_transactions; i++) begin
      if(((drv_trans.inp_valid == 2'b10) || (drv_trans.inp_valid == 2'b01)) && drv_trans.ce &&
         ((drv_trans.mode && (drv_trans.cmd inside {[0:3],[8:10]})) || (!drv_trans.mode && (drv_trans.cmd inside {[0:5],[12:13]})))) begin

        for(int j = 0; j < 16; j++) begin
          $display("time [%0t], inside loop j = %0d", $time, j);

          @(vif.driver_cb);

          if (drv_trans.randomize() with {
            cmd == local::cmd_fixed;
            mode == local::mode_fixed;
            ce == local::ce_fixed;
          }) begin

            if(drv_trans.inp_valid == 2'b11) begin
              vif.driver_cb.ce <= drv_trans.ce;
              vif.driver_cb.cin <= drv_trans.cin;
              vif.driver_cb.mode <= drv_trans.mode;
              vif.driver_cb.op_a <= drv_trans.op_a;
              vif.driver_cb.op_b <= drv_trans.op_b;
              vif.driver_cb.cmd <= drv_trans.cmd;
              vif.driver_cb.inp_valid <= drv_trans.inp_valid;
              break;
            end
            else begin
              vif.driver_cb.ce <= ce_fixed;
              vif.driver_cb.cin <= drv_trans.cin;
              vif.driver_cb.mode <= mode_fixed;
              vif.driver_cb.op_a <= drv_trans.op_a;
              vif.driver_cb.op_b <= drv_trans.op_b;
              vif.driver_cb.cmd <= cmd_fixed;
              vif.driver_cb.inp_valid <= drv_trans.inp_valid;
            end
          end
          else begin
            `uvm_error(get_type_name(), "Randomization failed")
          end
        end
      end
      else if(drv_trans.inp_valid == 2'b11) begin
        vif.driver_cb.ce <= drv_trans.ce;
        vif.driver_cb.cin <= drv_trans.cin;
        vif.driver_cb.mode <= drv_trans.mode;
        vif.driver_cb.op_a <= drv_trans.op_a;
        vif.driver_cb.op_b <= drv_trans.op_b;
        vif.driver_cb.cmd <= drv_trans.cmd;
        vif.driver_cb.inp_valid <= drv_trans.inp_valid;
        @(vif.driver_cb);
      end
    end
  endtask
endclass
[nehabangera@feserver alu_uvm]$ cat my_mon*
class my_monitor extends uvm_monitor;
  `uvm_component_utils(my_monitor)

  // Analysis port to broadcast observed transactions
  uvm_analysis_port#(seq_item) item_collected_port;

  // Transaction object
  seq_item mon_trans;

  // Virtual interface
  virtual alu_interface vif;

  // Constructor
  function new(string name = "my_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
    mon_trans = new();
  endfunction

  // Build phase: fetch virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_interface)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Failed to get the virtual interface handle")
    end
  endfunction

  // Helper: check if command is multiplication
  function bit multiplication_check();
    if (vif.monitor_cb.cmd inside {4'd9, 4'd10} && vif.monitor_cb.mode)
      return 1;
    else
      return 0;
  endfunction

  // Run phase: sample DUT signals and broadcast
  virtual task run_phase(uvm_phase phase);
    forever begin
      // Sync with clocking block before transactions
      repeat(3) @(vif.monitor_cb);

      for (int i = 0; i < `no_of_transactions; i++) begin
        repeat(1) @(vif.monitor_cb);

        if (multiplication_check()) begin
          // Multiplication operations take more cycles
          repeat(2) @(vif.monitor_cb);
        end

        // Capture DUT outputs
        #0;
        mon_trans.res   = vif.monitor_cb.res;
        mon_trans.oflow = vif.monitor_cb.oflow;
        mon_trans.cout  = vif.monitor_cb.cout;
        mon_trans.err   = vif.monitor_cb.err;
        mon_trans.g     = vif.monitor_cb.g;
        mon_trans.e     = vif.monitor_cb.e;
        mon_trans.l     = vif.monitor_cb.l;

        // Print for debug
       `uvm_info("MONITOR",$sformatf("Result=0x%h, Flags: g=%b, e=%b, l=%b, Cout=%b, OF=%b, Err=%b",
          mon_trans.res, mon_trans.g, mon_trans.e, mon_trans.l,
          mon_trans.cout, mon_trans.oflow, mon_trans.err), UVM_MEDIUM);

        // Write to analysis port (scoreboard + coverage receive this)
        item_collected_port.write(mon_trans);

        repeat(1) @(vif.monitor_cb);
      end

      $display("Monitor task done");
    end
  endtask
endclass

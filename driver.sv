
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

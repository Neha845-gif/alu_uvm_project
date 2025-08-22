
class my_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(my_scoreboard)

    // Analysis ports from driver and monitor
  // uvm_analysis_imp_driver #(seq_item, my_scoreboard) drv_export;
  // uvm_analysis_imp_monitor #(seq_item, my_scoreboard) mon_export;

    // TLM FIFOs for thread-safe operation
    uvm_tlm_analysis_fifo #(seq_item) drv_fifo;
    uvm_tlm_analysis_fifo #(seq_item) mon_fifo;

    int match, mismatch;
    virtual alu_interface vif;

    function new(string name = "my_scoreboard", uvm_component parent);
        super.new(name, parent);

    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create FIFOs
        drv_fifo = new("drv_fifo", this);
        mon_fifo = new("mon_fifo", this);

        // Create analysis exports
    //  drv_export = new("drv_export", this);
    //  mon_export = new("mon_export", this);

        if(!uvm_config_db#(virtual alu_interface)::get(this,"","vif",vif))
            `uvm_error(get_type_name(),"failed to get the virtual interface")
    endfunction

    // Connect phase - connect exports to FIFOs
  //  function void connect_phase(uvm_phase phase);
    //    super.connect_phase(phase);
      //  drv_export.connect(drv_fifo.analysis_export);
      //  mon_export.connect(mon_fifo.analysis_export);
   // endfunction

    // Write from driver
    function void write_driver(seq_item seq);
        if(seq == null) begin
            `uvm_error(get_type_name(),"received null transaction from driver");
            return;
        end
        `uvm_info("SCB_DRV", $sformatf("Driver seq: op_a=0x%0h, op_b=0x%0h, cmd=0x%0h, mode=%0d",
                  seq.op_a, seq.op_b, seq.cmd, seq.mode), UVM_HIGH)
    endfunction

    // Write from monitor
    function void write_monitor(seq_item seq);
        if(seq == null) begin
            `uvm_error(get_full_name(),"received null transaction from monitor");
            return;
        end
        `uvm_info("SCB_MON", $sformatf("Monitor seq: res=0x%0h, cout=%0d", seq.res, seq.cout), UVM_HIGH)
    endfunction

    task run_phase(uvm_phase phase);
        seq_item drv_item, exp_item, mon_item;

        // Wait for reset to be released
        wait(vif.rst == 0);
        `uvm_info("SCB", "Reset released, starting scoreboard", UVM_MEDIUM)

        forever begin
            // Get transactions from FIFOs (blocking calls)
            drv_fifo.get(drv_item);
            mon_fifo.get(mon_item);

            `uvm_info("SCB_PROC", $sformatf("Processing: drv_cmd=0x%0h, mon_res=0x%0h",
                      drv_item.cmd, mon_item.res), UVM_HIGH)

            exp_item = seq_item::type_id::create("exp_item");
            exp_item.copy(drv_item);

            run_ref_model(drv_item, exp_item);
            compare_and_report(mon_item, exp_item);
        end
    endtask

    task run_ref_model(input seq_item seq, ref seq_item exp_item);
        int shift;
        if(seq == null) begin
            `uvm_error(get_full_name(), "input transaction seq is null")
            return;
        end

        if(vif.rst) begin
            exp_item.res = 0;
            exp_item.cout = 0;
            exp_item.oflow = 0;
            exp_item.g = 0;
            exp_item.l = 0;
            exp_item.e = 0;
            exp_item.err = 0;
            return;
        end

        // Initialize outputs
        exp_item.res = 0;
        exp_item.cout = 0;
        exp_item.oflow = 0;
        exp_item.g = 0;
        exp_item.l = 0;
        exp_item.e = 0;
        exp_item.err = 0;

        if((seq.cmd == 4'd9 || seq.cmd == 4'd10) && !seq.mode && seq.ce && (seq.inp_valid == 2'd3)) begin
            repeat(2) @(posedge vif.clk);
        end

        `uvm_info("REF_MODEL", $sformatf("cmd=0x%0h, mode=%0d, inp_valid=%0b",
                  seq.cmd, seq.mode, seq.inp_valid), UVM_HIGH)

        if(seq.ce) begin
            case(seq.inp_valid)
                2'b11: begin
                    case(seq.mode)
                        1'b1: begin // Arithmetic mode
                            case(seq.cmd)
                                4'd0: begin
                                    {exp_item.cout, exp_item.res} = seq.op_a + seq.op_b;
                                end
                                4'd1: begin
                                    exp_item.res = seq.op_a - seq.op_b;
                                    exp_item.oflow = (seq.op_a < seq.op_b) ? 1'b1 : 1'b0;
                                end
                                4'd2: begin
                                    {exp_item.cout, exp_item.res} = seq.op_a + seq.op_b + seq.cin;
                                end
                                4'd3: begin
                                    exp_item.res = seq.op_a - seq.op_b - seq.cin;
                                    exp_item.oflow = (seq.op_a < (seq.op_b + seq.cin)) ? 1'b1 : 1'b0;
                                end
                                4'd4: exp_item.res = seq.op_a + 1;
                                4'd5: exp_item.res = seq.op_a - 1;
                                4'd6: exp_item.res = seq.op_b + 1;
                                4'd7: exp_item.res = seq.op_b - 1;
                                4'd8: begin
                                    exp_item.e = (seq.op_a == seq.op_b) ? 1'b1 : 1'b0;
                                    exp_item.g = (seq.op_a > seq.op_b) ? 1'b1 : 1'b0;
                                    exp_item.l = (seq.op_a < seq.op_b) ? 1'b1 : 1'b0;
                                end
                                4'd9: exp_item.res = (seq.op_a + 1) * (seq.op_b + 1);
                                4'd10: exp_item.res = (seq.op_a << 1) * seq.op_b;
                                default: begin
                                    exp_item.err = 1'b1;
                                end
                            endcase
                        end
                        1'b0: begin // Logical mode
                            case(seq.cmd)
                                4'd0: exp_item.res = seq.op_a & seq.op_b;
                                4'd1: exp_item.res = ~(seq.op_a & seq.op_b);
                                4'd2: exp_item.res = seq.op_a | seq.op_b;
                                4'd3: exp_item.res = ~(seq.op_a | seq.op_b);
                                4'd4: exp_item.res = seq.op_a ^ seq.op_b;
                                4'd5: exp_item.res = ~(seq.op_a ^ seq.op_b);
                                4'd6: exp_item.res = ~seq.op_a;
                                4'd7: exp_item.res = ~seq.op_b;
                                4'd8: exp_item.res = seq.op_a >> 1;
                                4'd9: exp_item.res = seq.op_a << 1;
                                4'd10: exp_item.res = seq.op_b >> 1;
                                4'd11: exp_item.res = seq.op_b << 1;
                                4'd12: begin
                                    shift = seq.op_b[2:0];
                                    exp_item.res = (seq.op_a << shift) | (seq.op_a >> (`width - shift));
                                    exp_item.err = (|seq.op_b[`width-1:3]) ? 1'b1 : 1'b0;
                                end
                                4'd13: begin
                                    shift = seq.op_b[2:0];
                                    exp_item.res = (seq.op_a >> shift) | (seq.op_a << (`width - shift));
                                    exp_item.err = (|seq.op_b[`width-1:3]) ? 1'b1 : 1'b0;
                                end
                                default: begin
                                    exp_item.err = 1'b1;
                                end
                            endcase
                        end
                    endcase
                end
                2'b01: begin
                    case(seq.mode)
                        1'b1: begin
                            case(seq.cmd)
                                4'd4: exp_item.res = seq.op_a + 1;
                                4'd5: exp_item.res = seq.op_a - 1;
                                default: exp_item.err = 1'b1;
                            endcase
                        end
                        1'b0: begin
                            case(seq.cmd)
                                4'd6: exp_item.res = ~seq.op_a;
                                4'd8: exp_item.res = seq.op_a >> 1;
                                4'd9: exp_item.res = seq.op_a << 1;
                                default: exp_item.err = 1'b1;
                            endcase
                        end
                    endcase
                end
                default: begin
                    exp_item.err = 1'b1;
                end
            endcase
        end
    endtask

    task compare_and_report(seq_item dut, seq_item exp_item);
        bit comparison_pass;

        comparison_pass = ((exp_item.res === dut.res) &&
                          (exp_item.cout === dut.cout) &&
                          (exp_item.oflow === dut.oflow) &&
                          (exp_item.g === dut.g) &&
                          (exp_item.l === dut.l) &&
                          (exp_item.e === dut.e) &&
                          (exp_item.err === dut.err));

        if(comparison_pass) begin
            match++;
            `uvm_info("MATCH", $sformatf("PASS: dut_res=0x%0h, exp_res=0x%0h", dut.res, exp_item.res), UVM_MEDIUM)
        end
        else begin
            mismatch++;
            `uvm_error("MISMATCH", $sformatf("FAIL: cmd=0x%0h, op_a=0x%0h, op_b=0x%0h\nDUT: res=0x%0h, cout=%0b, oflow=%0b, e=%0b, l=%0b, g=%0b, err=%0b\nEXP: res=0x%0h, cout=%0b, oflow=%0b, e=%0b, l=%0b, g=%0b, err=%0b",
                dut.cmd, dut.op_a, dut.op_b,
                dut.res, dut.cout, dut.oflow, dut.e, dut.g, dut.l, dut.err,
                exp_item.res, exp_item.cout, exp_item.oflow, exp_item.e, exp_item.g, exp_item.l, exp_item.err))
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB_SUMMARY", $sformatf("Scoreboard Results:\nMatches: %0d\nMismatches: %0d\nSuccess Rate: %0.1f%%",
                  match, mismatch, (match*100.0)/(match+mismatch)), UVM_MEDIUM)
    endfunction

endclass

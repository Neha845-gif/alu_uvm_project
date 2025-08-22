`uvm_analysis_imp_decl(_mon_cg)
`uvm_analysis_imp_decl(_drv_cg)

class my_coverage extends uvm_component;

    `uvm_component_utils(my_coverage)

    uvm_analysis_imp_mon_cg #(seq_item, my_coverage) aport_mon1;
    uvm_analysis_imp_drv_cg #(seq_item, my_coverage) aport_drv1;

    seq_item mon_trans, drv_trans;
    real mon_cov, drv_cov;

    // FIX: Use different names for covergroup instances
    covergroup drv_cg_inst;
        option.per_instance = 1;

        cp_op_a: coverpoint drv_trans.op_a {
            bins opa_bins[] = {[0:255]};
        }

        cp_op_b: coverpoint drv_trans.op_b {
            bins opb_bins[] = {[0:255]};
        }

        cp_ce: coverpoint drv_trans.ce {
            bins ce_0 = {0};
            bins ce_1 = {1};
        }

        cp_cin: coverpoint drv_trans.cin {
            bins cin_0 = {0};
            bins cin_1 = {1};
        }

        cp_mode: coverpoint drv_trans.mode {
            bins mode_0 = {0};
            bins mode_1 = {1};
        }

        cp_inp_vld: coverpoint drv_trans.inp_valid {
            bins inp_valid_bins[] = {[0:3]};
        }

        cp_cmd: coverpoint drv_trans.cmd {
            bins add_and          = {0};
            bins sub_nand         = {1};
            bins add_cin_or       = {2};
            bins sub_cin_nor      = {3};
            bins inc_a_xor        = {4};
            bins dec_a_xnor       = {5};
            bins inc_b_not_a      = {6};
            bins dec_b_not_b      = {7};
            bins cmp_shr1_a       = {8};
            bins inc_mul_shl1_a   = {9};
            bins shift_mul_shr1_b = {10};
            bins shl1_            = {11};
            bins rol_a_b          = {12};
            bins ror_a_b          = {13};
        }

        cross_1: cross cp_inp_vld, cp_cmd;
        cross_2: cross cp_cmd, cp_mode;
        cross_3: cross cp_mode, cp_inp_vld;
    endgroup

    covergroup mon_cg_inst;
        option.per_instance = 1;

        cp_res: coverpoint mon_trans.res {
            bins res_val[] = {[-255:255]}; // FIX: Fixed range syntax
        }

        cp_oflow: coverpoint mon_trans.oflow {
            bins oflow_val[] = {0,1};
        }

        cp_err: coverpoint mon_trans.err {
            bins err_val[] = {0,1};
        }

        cp_cout: coverpoint mon_trans.cout {
            bins cout_val[] = {0,1};
        }

        cp_g: coverpoint mon_trans.g {
            bins g_val[] = {0,1};
        }

        cp_l: coverpoint mon_trans.l {
            bins l_val[] = {0,1};
        }

        cp_e: coverpoint mon_trans.e {
            bins e_val[] = {0,1};
        }
    endgroup

    function new(string name = "my_coverage", uvm_component parent);
        super.new(name, parent);
        // FIX: Proper covergroup instantiation
        drv_cg_inst = new();
        mon_cg_inst = new();
        aport_drv1 = new("aport_drv1", this);
        aport_mon1 = new("aport_mon1", this);
    endfunction

    function void write_drv_cg(seq_item seq);
        drv_trans = seq;
        drv_cg_inst.sample();
        drv_cov = drv_cg_inst.get_coverage();

        `uvm_info(get_type_name(),$sformatf("driver transaction at time [%0t] : op_a = %0d, op_b = %0d, cmd = %0d, mode = %0d, ce = %0d, cin = %0d, inp_valid = %0b",$time, drv_trans.op_a, drv_trans.op_b, drv_trans.cmd, drv_trans.mode, drv_trans.ce, drv_trans.cin, drv_trans.inp_valid),UVM_MEDIUM)
    endfunction

    function void write_mon_cg(seq_item seq);
        mon_trans = seq;
        mon_cg_inst.sample();
        mon_cov = mon_cg_inst.get_coverage(); // FIX: Changed variable name

        `uvm_info(get_type_name(),$sformatf("monitor transaction at time [%0t] : res = %0d, cout = %0b, oflow = %0b, err = %0b, g = %0b, l = %0b, e = %0b",$time, mon_trans.res, mon_trans.cout, mon_trans.oflow, mon_trans.err, mon_trans.g, mon_trans.l, mon_trans.e),UVM_MEDIUM)
    endfunction

    function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("[DRIVER] coverage ---------> %0.2f%%", drv_cov), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("[MONITOR] coverage ---------> %0.2f%%", mon_cov), UVM_MEDIUM)
    endfunction

endclass

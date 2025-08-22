
class my_env extends uvm_env;

    my_agent agt;
    my_scoreboard scb;
    my_coverage cov;

    `uvm_component_utils(my_env)

    function new(string name = "my_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = my_agent::type_id::create("agt", this);
        scb = my_scoreboard::type_id::create("scb", this);
        cov = my_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.drv.item_collect_port.connect(scb.drv_fifo.analysis_export);
        agt.mon.item_collected_port.connect(scb.mon_fifo.analysis_export);
        agt.mon.item_collected_port.connect(cov.aport_mon1);
        agt.drv.item_collect_port.connect(cov.aport_drv1);
    endfunction

endclass

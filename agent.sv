class my_agent extends uvm_agent;

`uvm_component_utils(my_agent)

function new(string name = "my_agent", uvm_component parent = null);
super.new(name, parent);
endfunction

my_driver drv;
my_sequencer sqr;
my_monitor mon;


function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(get_is_active() == UVM_ACTIVE) begin
drv = my_driver::type_id::create("drv", this);
sqr = my_sequencer::type_id::create("sqr", this);
end
mon = my_monitor::type_id::create("mon", this);
endfunction

function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
if(get_is_active() == UVM_ACTIVE)begin
drv.seq_item_port.connect(sqr.seq_item_export);
end
endfunction


endclass

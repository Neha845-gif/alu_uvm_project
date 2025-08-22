class my_test extends uvm_test;

`uvm_component_utils(my_test)

my_env envt;

function new(string name = "my_test", uvm_component parent = null);
super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
envt = my_env::type_id::create("envt", this);
endfunction

virtual task run_phase(uvm_phase phase);
my_sequence sqc;
phase.raise_objection(this);
sqc = my_sequence::type_id::create("sqc", this);
sqc.start(envt.agt.sqr);
phase.drop_objection(this);
endtask

endclass


class my_test1 extends my_test;
        `uvm_component_utils(my_test1)

        function new(string name = "my_test1", uvm_component parent = null);
                super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
                my_sequence1 seq;
                phase.raise_objection(this);
                        seq = my_sequence1::type_id::create("seq");
                        seq.start(envt.agt.sqr);

                phase.drop_objection(this);
        endtask
endclass


class my_test2 extends my_test;
        `uvm_component_utils(my_test2)

        function new(string name = "my_test2", uvm_component parent = null);
                super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
                my_sequence2 seq;
                phase.raise_objection(this);
                        seq = my_sequence2::type_id::create("seq");
                        seq.start(envt.agt.sqr);

                phase.drop_objection(this);
        endtask
endclass

class my_test3 extends my_test;
        `uvm_component_utils(my_test3)

        function new(string name = "my_test3", uvm_component parent = null);
                super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
                my_sequence3 seq;
                phase.raise_objection(this);
                        seq = my_sequence3::type_id::create("seq");
                        seq.start(envt.agt.sqr);

                phase.drop_objection(this);
        endtask
endclass


/*class my_test4 extends my_test;
        `uvm_component_utils(my_test4)

        function new(string name = "my_test4", uvm_component parent = null);
                super.new(name, parent);
        endfunction

        virtual task run_phase(uvm_phase phase);
                my_sequence4 seq;
                phase.raise_objection(this);
                        seq = my_sequence4::type_id::create("seq",this);
                        seq.start(envt.agt.sqr);

                phase.drop_objection(this);
        endtask
endclass */

class my_regression_test extends my_test;
        `uvm_component_utils(my_regression_test)

        function new(string name = "my_regression_test", uvm_component parent = null);
                super.new(name, parent);
        endfunction


virtual task run_phase(uvm_phase phase);
                my_regression seq;
                phase.raise_objection(this);
                        seq = my_regression::type_id::create("seq");
                        seq.start(envt.agt.sqr);

                phase.drop_objection(this);
        endtask
endclass

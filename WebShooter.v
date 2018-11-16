
`define WEBFLUID_STANDBY 2'b00
`define WEBFLUID_FAILURE_NOT_ENOUGH 2'b01
`define WEBFLUID_FAILURE_EMPTY 2'b10
`define WEBFLUID_FAILURE_SUCCESS 2'b11

`define ADVANCE_COUNTER_NO_CHANGE	'b00
`define ADVANCE_COUNTER_DECREMENT	'b01
`define ADVANCE_COUNTER_SET			'b10

module AdvanceDownCounter(clk, amount, mode, data, underflow);
	parameter n = 8;
	input clk;
	input [n-1:0] amount;
	input [1:0] mode;
	output underflow;
	reg underflow;
	
	output [n-1:0]data;
	reg [n-1:0] data;
	
	initial begin
		data = 0;
		underflow = 0;
	end
	
	always @(posedge clk) begin
		if(mode == `ADVANCE_COUNTER_SET) begin
			underflow = 0;
			data = amount;
		end
		else if(mode == `ADVANCE_COUNTER_DECREMENT) begin
			if(amount > data) begin
				underflow = 1;
			end
			else begin
				underflow = 0;
				data = data - amount;
			end
		end
	end
	
	
endmodule

`define CONTROLLER_DEAD 	'b0000
`define CONTROLLER_WAITING 	'b0001
`define CONTROLLER_REFILL	'b0010
`define CONTROLLER_CHECK	'b0100
`define CONTROLLER_FIRE		'b1000

module Controller(trigger, refill, enough, kill, clk, f, e, t);
	input trigger;
	input refill;
	input enough;
	input kill;
	input clk;
	output [1:0] f;
	output [1:0] e;
	output [1:0] t;
	
	reg [1:0] f;
	reg [1:0] e;
	reg [1:0] t;
	
	reg [3:0] current_state;
	reg [3:0] temp_state;
	
	task changeStateFromWaiting;
		if(!trigger && refill) begin
			temp_state = `CONTROLLER_REFILL;
			f = `ADVANCE_COUNTER_SET;
			e = `ADVANCE_COUNTER_NO_CHANGE;
			t = `ADVANCE_COUNTER_NO_CHANGE;
		end
		else if(trigger && !refill) begin
			temp_state = `CONTROLLER_CHECK;
			f = `ADVANCE_COUNTER_NO_CHANGE;
			e = `ADVANCE_COUNTER_NO_CHANGE;
			t = `ADVANCE_COUNTER_NO_CHANGE;
		end
		else begin
			temp_state = current_state;
		end
	endtask
	
	task changeStateFromRefill;
		if(!refill)
			temp_state = `CONTROLLER_WAITING;
		else temp_state = current_state;
	endtask
	
	task changeStateFromCheck;
		if(enough) begin
			temp_state = `CONTROLLER_FIRE;
			f = `ADVANCE_COUNTER_DECREMENT;
			e = `ADVANCE_COUNTER_DECREMENT;
			t = `ADVANCE_COUNTER_DECREMENT;
		end
		else if(!trigger) begin
			temp_state = `CONTROLLER_WAITING;
			f = `ADVANCE_COUNTER_NO_CHANGE;
			e = `ADVANCE_COUNTER_NO_CHANGE;
			t = `ADVANCE_COUNTER_NO_CHANGE;
		end
	endtask
	
	task changeStateFromFire;
		if(kill) begin
			//$display("%b", kill);
			temp_state = `CONTROLLER_DEAD;
			f = `ADVANCE_COUNTER_NO_CHANGE;
			e = `ADVANCE_COUNTER_NO_CHANGE;
			t = `ADVANCE_COUNTER_NO_CHANGE;
		end
		else if(!trigger && !refill) begin
			//$display("%b", kill);
			temp_state = `CONTROLLER_WAITING;
			f = `ADVANCE_COUNTER_NO_CHANGE;
			e = `ADVANCE_COUNTER_NO_CHANGE;
			t = `ADVANCE_COUNTER_NO_CHANGE;
		end
		else begin
			temp_state = current_state;
			f = `ADVANCE_COUNTER_NO_CHANGE;
			e = `ADVANCE_COUNTER_NO_CHANGE;
			t = `ADVANCE_COUNTER_NO_CHANGE;
		end
	endtask
	
	always @(posedge clk) begin
		//assign temp_state = current_state;
		case(current_state)
			`CONTROLLER_WAITING:	changeStateFromWaiting();
			`CONTROLLER_FIRE:		changeStateFromFire();
			`CONTROLLER_CHECK:		changeStateFromCheck();
			`CONTROLLER_REFILL:		changeStateFromRefill();
			`CONTROLLER_DEAD:
				begin
					$display("Device has run out of energy!");
					$finish;
				end
		endcase
		current_state = temp_state;
	end
	
	
endmodule

module SufficientResourceChecker(current_f,current_t,current_e, current_targets,needed_f,needed_t,needed_e, needed_targets, clk, enough_f, enough_t, enough_e, target_equals);
	input [4:0]current_f;
	input [8:0]current_e;
	input [6:0]current_t;
	input [4:0]current_targets;
	
	input [4:0]needed_f;
	input [8:0]needed_e;
	input [6:0]needed_t;
	input [4:0]needed_targets;
	
	input clk;
	
	output enough_e;
	output enough_t;
	output enough_f;
	output target_equals;
	
	reg enough_e;
	reg enough_t;
	reg enough_f;
	reg target_equals;
	
	
	always @(posedge clk) begin
		enough_e = current_e >= needed_e;
		enough_f = current_f >= needed_f;
		enough_t = current_t >= needed_t;
		//$display("hjgjhg %d", enough_t);
		target_equals = needed_targets == current_targets;
	end
	
	
	
	
endmodule

`define FIRE_MODE_SWING 	'b000
`define FIRE_MODE_RICOCHET	'b001
`define FIRE_MODE_SPLITTER	'b011
`define FIRE_MODE_GRENADE	'b111
`define FIRE_MODE_TASER		'b110
`define FIRE_MODE_RAPID		'b100
`define FIRE_MODE_TRACER	'b101

module ResourceCalculator(mode, num_t, fluid, tracer, energy, targets);
	input [2:0] mode;
	input [4:0]num_t;
	output [8:0]energy;
	output [6:0]tracer;
	output [4:0]fluid;
	output [4:0]targets;
	
	reg [4:0]targets;
	reg [8:0]energy;
	reg [6:0]tracer;
	reg [4:0]fluid;
	
	always @(*) begin
		case(mode)
			`FIRE_MODE_SWING:
			begin
				targets = 1;
				fluid = 1;
				energy = 1;
				tracer = 0;
			end
			`FIRE_MODE_RICOCHET: begin
				targets = 1;
				fluid = 1;
				energy = 2;
				tracer = 0;
			end
			`FIRE_MODE_SPLITTER: begin
				targets = num_t;
				fluid = num_t;
				energy = num_t + 1;
				tracer = 0;
			end
			`FIRE_MODE_GRENADE: begin
				targets = 1;
				fluid = 16;
				energy = 4;
				tracer = 0;
			end
			`FIRE_MODE_TASER: begin
				targets = 1;
				fluid = 1;
				energy = 16;
				tracer = 8;
			end
			`FIRE_MODE_RAPID: begin
				targets = 1;
				fluid = 1;
				energy = 1;
				tracer = 0;
			end
			`FIRE_MODE_TRACER: begin
				targets = 1;
				fluid = 1;
				energy = 1;
				tracer = 4;
			end
		endcase
	end
	
endmodule

module Mux2_1(a,b,s,o);
	parameter n = 1;
	
	input [n-1:0]a;
	input [n-1:0]b;
	input s;
	output [n-1:0] o;
	reg [n-1:0] o;
	
	always @(*) begin
		if(s)begin
			o = b;
		end
		else begin
			o = a;
		end
	end
endmodule

module IsSetFluid(in, out);
	input [1:0] in;
	output out;
	assign out = in==`ADVANCE_COUNTER_SET;
endmodule

module KillChecker(energy_amount,kill);
	input [8:0]energy_amount;
	output kill;
	reg kill;
	
	always @(*) begin
		if(energy_amount == 0) begin
			kill = 1;
		end
		else kill = 0;
	end
endmodule

module ResourceOutDisplay(e_e,f_e,t_e);
	input e_e;
	input f_e;
	input t_e;
	task display_e;
		begin
			if(!e_e)
			begin
				$display("Not enough energy %d!", e_e);
			end
		end
	endtask
	task display_f;
		begin
			if(!f_e)
			begin
				$display("Not enough fluid %d!", f_e);
			end
		end
	endtask
	task display_t;
		begin
			if(!t_e)
			begin
				$display("Not enough tracer! %d", t_e);
			end
		end
	endtask
endmodule


module WebShooter(trigger, refill, fire_mode, not_enough, target_cnt, shoot, clk);
	input trigger;
	input refill;
	input [2:0] fire_mode;
	input [4:0] target_cnt;
	input clk;
	output shoot;
	reg shoot;
	output not_enough;
	
	
	wire enough_e;
	wire enough_f;
	wire enough_t;
	wire target_equal;
	wire kill_line;
	wire enough_line;
	
	wire [1:0]f_mode_line;
	wire [1:0]e_mode_line;
	wire [1:0]t_mode_line;
	
	wire [4:0] decrement_amount_fluid;
	wire [4:0] to_fluid_amount;
	wire to_fluid_mux_set;
	localparam [4:0]REFILL_AMOUNT = 16;
	wire [4:0]amount_of_fluid;
	
	wire fluid_underflow;
	wire energy_underflow;
	wire tracer_underflow;
	wire [6:0] decrement_amount_tracer;
	wire [6:0] amount_of_tracer;
	wire [8:0] decrement_amount_energy;
	wire [8:0] amount_of_energy;
	wire [4:0] target_from_rc;
	
	ResourceOutDisplay enough_disp(enough_e, enough_f, enough_t);
	Controller controller(trigger, refill, enough_line, kill_line, clk, f_mode_line, e_mode_line, t_mode_line);
	IsSetFluid is_set_fluid(f_mode_line, to_fluid_mux_set);
	Mux2_1 #(5) fluid_mux(decrement_amount_fluid, REFILL_AMOUNT, to_fluid_mux_set, to_fluid_amount); 
	AdvanceDownCounter #(5) fluid_counter(clk, to_fluid_amount,f_mode_line,amount_of_fluid, fluid_underflow);
	AdvanceDownCounter #(9) energy_counter(clk, decrement_amount_energy,e_mode_line,amount_of_energy, energy_underflow);
	AdvanceDownCounter #(7) tracer_counter(clk, decrement_amount_tracer,t_mode_line,amount_of_tracer, tracer_underflow);
	ResourceCalculator resource_calculator(fire_mode, target_cnt, decrement_amount_fluid, decrement_amount_tracer, decrement_amount_energy, target_from_rc);
	SufficientResourceChecker sufficient_resource_checker(amount_of_fluid, amount_of_tracer, amount_of_energy, target_from_rc,decrement_amount_fluid, decrement_amount_tracer, decrement_amount_energy, target_cnt,clk,enough_f, enough_t, enough_e, target_equal); 
	KillChecker kill_checker(amount_of_energy, kill_line);
	
	assign enough_line = enough_e && enough_f && enough_t && target_equal;
	assign not_enough = fluid_underflow || energy_underflow || tracer_underflow;
	
	
	//assign enough_line = 1;
	//assign kill_line = 0;
	
endmodule

`define DISPLAY_ALL $display("%4b|%2b|%2b|%2b||||%b %b %b %b|",controller.current_state,f,e,t,trigger,refill,enough,kill)

`define SHOOT\
#60\
trigger = 1;\
#60\
web_shooter.enough_disp.display_e;\
web_shooter.enough_disp.display_f;\
web_shooter.enough_disp.display_t;\
trigger = 0;\
#60
`define RF\
#60\
refill = 1;\
#60\
refill = 0;



module TestBench;
	
	reg clk;
	reg trigger;
	reg refill;
	reg [2:0] fire_mode;
	reg [4:0] target_amount;
	
	wire not_enough;
	wire shoot;
	
	WebShooter web_shooter(trigger, refill, fire_mode, not_enough, target_amount, shoot, clk);

	
	initial begin
		#2
		forever
			begin
				#5 clk = 0 ;//Clock Low		
				#5 clk = 1 ;//Clock High
				//$display("Enough %b", en);
				//`DISPLAY_ALL;
			end
	end
	
	initial begin
		trigger = 0;
		refill = 0;
		fire_mode = `FIRE_MODE_SWING;
		target_amount = 1;
		web_shooter.fluid_counter.data = 16;
		web_shooter.tracer_counter.data = 1;
		web_shooter.energy_counter.data = 256;
		web_shooter.controller.current_state = `CONTROLLER_WAITING;
		#20
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		$display("Setting fire mode to Splitter");
		fire_mode = `FIRE_MODE_TRACER;
		target_amount = 1;
		`SHOOT
		$display("I have %d %d %d   %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data, web_shooter.resource_calculator.tracer);
		
		$display("Dropp off");
		
		$finish;
    end
	
endmodule




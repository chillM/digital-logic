
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
			temp_state = `CONTROLLER_DEAD;
			f = `ADVANCE_COUNTER_NO_CHANGE;
			e = `ADVANCE_COUNTER_NO_CHANGE;
			t = `ADVANCE_COUNTER_NO_CHANGE;
		end
		else if(!trigger && !refill) begin
			temp_state = `CONTROLLER_WAITING;
			f = `ADVANCE_COUNTER_NO_CHANGE;
			e = `ADVANCE_COUNTER_NO_CHANGE;
			t = `ADVANCE_COUNTER_NO_CHANGE;
		end
		else begin
			temp_state = current_state;
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

module SufficientResourceChecker(current_f,current_t,current_e, current_targets,needed_f,needed_t,needed_e, needed_targets, clk, enough);
	input [4:0]current_f;
	input [8:0]current_e;
	input [6:0]current_t;
	input [4:0]current_targets;
	
	input [4:0]needed_f;
	input [8:0]needed_e;
	input [6:0]needed_t;
	input [4:0]needed_targets;
	
	input clk;
	
	output enough;
	reg enough;
	
	always @(posedge clk) begin
		
		if(current_f >= needed_f && current_t >= needed_t && current_e >= needed_e && needed_targets == current_targets) begin
			enough = 1;
		end
		else begin
			enough = 0;
		end
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

module KillChecker;
	
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
	
	
	wire enough_line;
	wire kill_line;
	
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
	
	Controller controller(trigger, refill, enough_line, kill_line, clk, f_mode_line, e_mode_line, t_mode_line);
	IsSetFluid is_set_fluid(f_mode_line, to_fluid_mux_set);
	Mux2_1 #(5) fluid_mux(decrement_amount_fluid, REFILL_AMOUNT, to_fluid_mux_set, to_fluid_amount); 
	AdvanceDownCounter #(5) fluid_counter(clk, to_fluid_amount,f_mode_line,amount_of_fluid, fluid_underflow);
	AdvanceDownCounter #(9) energy_counter(clk, decrement_amount_energy,e_mode_line,amount_of_energy, energy_underflow);
	AdvanceDownCounter #(7) tracer_counter(clk, decrement_amount_tracer,t_mode_line,amount_of_tracer, tracer_underflow);
	ResourceCalculator resource_calculator(fire_mode, target_cnt, decrement_amount_fluid, decrement_amount_tracer, decrement_amount_energy, target_from_rc);
	SufficientResourceChecker sufficient_resource_checker(amount_of_fluid, amount_of_tracer, amount_of_energy, target_from_rc,decrement_amount_fluid, decrement_amount_tracer, decrement_amount_energy, target_cnt,clk,enough_line); 
		
	
	
	//assign enough_line = 1;
	assign kill_line = 0;
	
endmodule

`define DISPLAY_ALL $display("%4b|%2b|%2b|%2b||||%b %b %b %b|",controller.current_state,f,e,t,trigger,refill,enough,kill)

`define SHOOT\
#30\
trigger = 1;\
#30\
trigger = 0;

`define RF\
#30\
refill = 1;\
#30\
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
		web_shooter.fluid_counter.data = 3;
		web_shooter.tracer_counter.data = 64;
		web_shooter.energy_counter.data = 256;
		web_shooter.controller.current_state = `CONTROLLER_WAITING;
		#20
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		//refill = 1;
		#20
		//refill = 0;
		#20
		`SHOOT
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		`SHOOT
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		`SHOOT
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		`SHOOT
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		`SHOOT
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		`SHOOT
		
		`SHOOT
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 16;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 14;
		`SHOOT;
		`RF;
		fire_mode = `FIRE_MODE_SPLITTER;
		target_amount = 13;
		`SHOOT;
		
		
		$display("Dropp off");
		$display("I have %d %d %d", web_shooter.fluid_counter.data,web_shooter.energy_counter.data,web_shooter.tracer_counter.data);
		$finish;
    end
	
endmodule




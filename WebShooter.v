`define WEBFLUID_STANDBY 2'b00
`define WEBFLUID_FAILURE_NOT_ENOUGH 2'b01
`define WEBFLUID_FAILURE_EMPTY 2'b10
`define WEBFLUID_FAILURE_SUCCESS 2'b11

`define ADVANCE_COUNTER_NO_CHANGE	'b00
`define ADVANCE_COUNTER_DECREMENT	'b01
`define ADVANCE_COUNTER_SET			'b10

//A counter that suports decrementing, setting, and no change moded
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

//The main control state machine.
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
	reg [3:0] prev_state;
	
	task changeStateFromWaiting; begin
		prev_state = `CONTROLLER_WAITING;
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
	end
	endtask
	
	task changeStateFromRefill; begin
		prev_state = `CONTROLLER_REFILL;
		if(!refill)
			temp_state = `CONTROLLER_WAITING;
		else temp_state = current_state;
	end
	endtask
	
	task changeStateFromCheck; begin
		prev_state = `CONTROLLER_CHECK;
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
	end
	endtask
	
	task changeStateFromFire; begin
		prev_state = `CONTROLLER_FIRE;
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

//This module will check if each resource has enough to preform the wanted fire
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

//This module calculates the required resources for the current mode
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

//A simple 2:1 mux
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

//This module connects to the set/dec mux connected to the fluid counter
module IsSetFluid(in, out);
	input [1:0] in;
	output out;
	assign out = in==`ADVANCE_COUNTER_SET;
endmodule

//This module checks if energy has run out, and generates the kill signal
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

//This is a display module, containing tasks for displaying resources and failures
module ResourceOutDisplay(e,f,t,e_e,f_e,t_e);
	input e_e;
	input f_e;
	input t_e;
	input [8:0] e;
	input [6:0] t;
	input [4:0] f;
	task display_fail;
		begin
			if(!e_e)
			begin
				$display("Not enough energy!");
			end
			if(!f_e)
			begin
				$display("Not enough fluid!");
			end
			if(!t_e)
			begin
				$display("Not enough tracer!");
			end
		end
	endtask
	task display_res;
		begin
			$display("Resources: %3d E| %2d F| %2d T", e,f,t);
		end
	endtask
endmodule


//This is the main component, holding every piece of the system
module WebShooter(trigger, refill, fire_mode, not_enough, target_cnt, shoot, clk);
	input trigger;
	input refill;
	input [2:0] fire_mode;
	input [4:0] target_cnt;
	input clk;
	output [2:0]shoot;
	reg [2:0] shoot;
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
	
	ResourceOutDisplay enough_disp(amount_of_energy,amount_of_fluid,amount_of_tracer, enough_e, enough_f, enough_t);
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
	
	initial begin
		shoot = 0;
		#2
		forever begin
			#10
			if(controller.current_state == `CONTROLLER_FIRE && controller.prev_state != `CONTROLLER_FIRE)
				shoot = shoot + 1;
		end
	end
	
	
	//assign enough_line = 1;
	//assign kill_line = 0;
	
endmodule


//This macro attempts to shot then displays the result
`define SHOOT\
$display("--------------------------------");\
#60\
trigger = 1;\
$display("Shooting...");\
if(shoot) $display("PEW!!! [||]=< ~~~~~~#");\
web_shooter.enough_disp.display_fail;\
#60\
web_shooter.enough_disp.display_res;\
trigger = 0;\
$display("--------------------------------");\
#60


//This macro refills and displays info
`define RF\
$display("Refilling");\
#60\
refill = 1;\
#60\
refill = 0;\
web_shooter.enough_disp.display_res;\
#60


module TestBench;
	
	reg clk;
	reg trigger;
	reg refill;
	reg [2:0] fire_mode;
	reg [4:0] target_amount;
	
	wire not_enough;
	wire [2:0]shoot;
	
	WebShooter web_shooter(trigger, refill, fire_mode, not_enough, target_amount, shoot, clk);

	
	initial begin
		#2
		forever
			begin
				#5 clk = 0 ;//Clock Low
				$realTimeDelay(50);
				$getUserInput(fire_mode, trigger, refill,target_amount);
				$display("%d %d %d %2d %2d",fire_mode, trigger, refill,target_amount, web_shooter.shoot);
				#5 clk = 1 ;//Clock High
				web_shooter.enough_disp.display_res;
				$display("Mode %3b", web_shooter.controller.current_state);
				$setDisplay(web_shooter.fluid_counter.data, web_shooter.energy_counter.data, web_shooter.tracer_counter.data);
				//$display("Enough %b", en);
				//`DISPLAY_ALL;
			end
	end
	
	initial begin
		trigger = 0;
		refill = 0;
		fire_mode = `FIRE_MODE_SWING;
		target_amount = 1;
		web_shooter.fluid_counter.data = 16;//initialize the fluid 
		web_shooter.tracer_counter.data = 64;//initialize the tracer
		web_shooter.energy_counter.data = 256;//initialize the energy
		web_shooter.controller.current_state = `CONTROLLER_WAITING;
		`RF;
		/*`SHOOT
		`SHOOT
		`SHOOT
		$display("Setting fire mode to Ricochet");
		fire_mode = `FIRE_MODE_RICOCHET;
		`SHOOT
		`SHOOT 
		$display("Setting fire mode to Splitter");
		fire_mode = `FIRE_MODE_SPLITTER;
		$display("Targeting 4 things");
		target_amount = 4;
		`SHOOT
		$display("Targeting 8 things");
		target_amount = 8;
		`SHOOT
		$display("Targeting 6 things");
		target_amount = 7;
		`SHOOT
		`RF
		$display("Targeting 1 thing");
		target_amount = 1;
		$display("Setting fire mode to Grenade");
		fire_mode = `FIRE_MODE_GRENADE;
		`SHOOT
		`SHOOT
		`RF
		$display("Setting fire mode to Taser");
		fire_mode = `FIRE_MODE_TASER;
		`SHOOT
		`SHOOT
		`SHOOT
		`SHOOT
		`SHOOT
		`SHOOT
		`SHOOT
		$display("Setting fire mode to Rapid");
		fire_mode = `FIRE_MODE_RAPID;
		`RF
		`SHOOT
		`SHOOT
		`SHOOT
		$display("Setting fire mode to Tracer");
		fire_mode = `FIRE_MODE_TRACER;
		`SHOOT
		`SHOOT
		`SHOOT 
		
		$display("Setting fire mode to Grenade");
		fire_mode = `FIRE_MODE_GRENADE;
		`RF
		while(shoot) begin
			`SHOOT;
			`RF;
		end
		$display("Setting fire mode to Rapid");
		fire_mode = `FIRE_MODE_RAPID;
		`SHOOT
		`SHOOT
		`SHOOT
		
		

		
		
		
		$display("Drop off");//If the program does not terminate naturaly
		$finish;
		*/
    end
	
endmodule



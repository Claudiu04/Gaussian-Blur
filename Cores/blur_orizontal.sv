`timescale 1ns / 1ps



module blur_horizontal#(

    parameter DATA_WIDTH = 8,
    parameter MAX_IMAGE_WIDTH = 3840

    )(

    input logic aclk,
    input logic aresetn,
    
    input logic [1:0] kernel_size, // 00 = 3x3 , 01 = 5x5 , 10 = 7x7, 11 = 9x9
    
    input  logic [31:0] width,
    
    //input from top
    input logic [DATA_WIDTH - 1 : 0] p_in,
    input logic p_valid_in,
    input logic p_last_in,
    
    //output to blur_veritcal
    output logic [DATA_WIDTH - 1 : 0] p_out,
    output logic p_valid_out,
    output logic p_last_out
    
    );
    
   
    logic [DATA_WIDTH - 1 : 0] h_window [0:8];
    
    
    logic [7:0] coeff [0:8];
    logic [3:0] shift_val;
    
    always_comb begin
    
        for (int i = 0; i < 9; i++) coeff[i] = 8'd0;
        shift_val = 4'd0;

        case (kernel_size)
            2'b00: begin // 3x3 (Sum = 4)
                coeff[3] = 8'd1; coeff[4] = 8'd2; coeff[5] = 8'd1;
                shift_val = 4'd2; 
            end
            2'b01: begin // 5x5 (Sum = 16)
                coeff[2] = 8'd1; coeff[3] = 8'd4; coeff[4] = 8'd6; coeff[5] = 8'd4; coeff[6] = 8'd1;
                shift_val = 4'd4; 
            end
            2'b10: begin // 7x7 (Sum = 64)
                coeff[1] = 8'd1; coeff[2] = 8'd6; coeff[3] = 8'd15; coeff[4] = 8'd20; coeff[5] = 8'd15; coeff[6] = 8'd6; coeff[7] = 8'd1;
                shift_val = 4'd6; 
            end
            2'b11: begin // 9x9 (Sum = 256)
                coeff[0] = 8'd1; coeff[1] = 8'd8; coeff[2] = 8'd28; coeff[3] = 8'd56; coeff[4] = 8'd70; coeff[5] = 8'd56; coeff[6] = 8'd28; coeff[7] = 8'd8; coeff[8] = 8'd1;
                shift_val = 4'd8; 
            end
        endcase
    end
    
    logic [15:0] col_counter;
    logic [15:0] col_pipe [4:0]; //at col_counter = 4 we do the first pixel so we need a delay of 4 cycles
    logic internal_valid;

    
    always_ff @(posedge aclk) begin
        if(!aresetn) begin
            col_counter <= 0;
            for (int i=0; i<5; i++) col_pipe[i] <= 0;
        end else begin
            
            if (internal_valid == 1) begin
                h_window[8] <= p_in;
                h_window[7] <= h_window[8];
                h_window[6] <= h_window[7];
                h_window[5] <= h_window[6];
                h_window[4] <= h_window[5];
                h_window[3] <= h_window[4];
                h_window[2] <= h_window[3];
                h_window[1] <= h_window[2];
                h_window[0] <= h_window[1];
                
                col_pipe[0] <= p_valid_in ? col_counter : (width - 1); 
                col_pipe[1] <= col_pipe[0];
                col_pipe[2] <= col_pipe[1];
                col_pipe[3] <= col_pipe[2];
                col_pipe[4] <= col_pipe[3];
            end
            
            if (p_valid_in == 1) begin
                if (p_last_in == 1) begin 
                    col_counter <= 0;
                end else if(col_counter == width - 1) begin
                    col_counter <= 0;
                end else begin
                    col_counter <= col_counter + 1;
                end
            end
            
        end
    end
    

    
    logic [DATA_WIDTH - 1 : 0] padded_window [0:8];
    
    always_comb begin
    
        padded_window = h_window;

    
        case (col_pipe[4])
        
            16'd0 : begin
            
                padded_window[3] = h_window[4];
                padded_window[2] = h_window[4];
                padded_window[1] = h_window[4];
                padded_window[0] = h_window[4];
            
            end
            
            16'd1 : begin
            
                padded_window[2] = h_window[3];
                padded_window[1] = h_window[3];
                padded_window[0] = h_window[3];
           
            end
           
            16'd2 : begin
           
                padded_window[1] = h_window[2];
                padded_window[0] = h_window[2];
           
            end
           
            16'd3 : begin
           
                padded_window[0] = h_window[1];
           
            end
            
            (width - 1) : begin
            
                padded_window[8 - 3] = h_window[4];
                padded_window[8 - 2] = h_window[4];
                padded_window[8 - 1] = h_window[4];
                padded_window[8] = h_window[4];
            
            end
            
            (width - 2) : begin
            
                padded_window[8 - 2] = h_window[5];
                padded_window[8 - 1] = h_window[5];
                padded_window[8] = h_window[5];
           
            end
           
            (width - 3) : begin
           
                padded_window[8 - 1] = h_window[6];
                padded_window[8] = h_window[6];
           
            end
           
            (width - 4) : begin
           
                padded_window[8] = h_window[7];
           
            end
                        
           
        endcase    
           
            
    
    end
    
    logic [DATA_WIDTH - 1 : 0] padded_window_reg [0:8];
    logic [15:0] mult_res [0:8];
    logic [19:0] sum_pipe1;
    logic [19:0] sum_pipe2;
    logic [19:0] sum_pipe3;
    logic [19:0] sum_res;
    
    always_ff @(posedge aclk) begin
    
        if(!aresetn) begin
        
            sum_res <= 0;
            sum_pipe1 <= 0;
            sum_pipe2 <= 0;
            sum_pipe3 <= 0;
            for (int i=0; i<9; i++) padded_window_reg[i] <= 0;
            for (int i=0; i<9; i++) mult_res[i] <= 0;
        
        end else begin
        
            if ( internal_valid == 1 ) begin
            
                for (int i=0; i<9; i++) padded_window_reg[i] <= padded_window[i];
                
                for (int i=0; i<9; i++) mult_res[i] <= padded_window_reg[i] * coeff[i];
                            
                sum_pipe1 <= mult_res[0] + mult_res[1] +  mult_res[2];
                
                sum_pipe2 <= mult_res[3] + mult_res[4] + mult_res[5];
                
                sum_pipe3 <= mult_res[6] + mult_res[7] + mult_res[8];
                
                sum_res <= sum_pipe1 + sum_pipe2 + sum_pipe3;
                
                p_out <= sum_res >> shift_val;
            
            end
                    
        end
    
    end
        
    
    logic flushing;
    logic [9:0] valid_pipe; 
    logic [9:0] last_pipe; 
    
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            flushing <= 0;
        end else begin
            if (p_valid_in && p_last_in) begin
                flushing <= 1; 
            end else if (flushing && last_pipe[0]) begin
                flushing <= 0;
            end
        end
    end
    
    assign internal_valid = p_valid_in | flushing;


     
    
    always_ff @(posedge aclk) begin
        if(!aresetn) begin
            valid_pipe <= 0;
            last_pipe <= 0;
        end else begin
            if (internal_valid) begin
                
                valid_pipe[9] <= p_valid_in; 
                valid_pipe[8:0] <= valid_pipe[9:1]; 
                
                last_pipe[9] <= p_last_in & p_valid_in;
                last_pipe[8:0] <= last_pipe[9:1];
            end
        end
    end
    
    assign p_valid_out = valid_pipe[0] & internal_valid;
    assign p_last_out  = last_pipe[0] & internal_valid;
    
endmodule

`timescale 1ns / 1ps

module blur_vertical #(
    parameter DATA_WIDTH = 8,
    parameter MAX_IMAGE_WIDTH = 3840
)(
    input logic aclk,
    input logic aresetn,
    
    input logic [1:0] kernel_size,
    
    input logic [31:0] width,
    input logic [31:0] height,
    
    //input from horizontal
    input logic [DATA_WIDTH - 1 : 0] p_in,
    input logic p_valid_in,
    input logic p_last_in,
    
    //output to filter
    output logic [DATA_WIDTH - 1 : 0] p_out,
    output logic p_valid_out,
    output logic p_last_out
);
    
    logic [DATA_WIDTH - 1 : 0] line_buffer [0:7][0 : MAX_IMAGE_WIDTH - 1];
    
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
    
    logic [DATA_WIDTH - 1 : 0] v_window [0:8];
    
    logic [15:0] col_counter;
    logic [15:0] row_counter;
    logic [15:0] out_col, out_row;
    logic output_active;
    
    logic [DATA_WIDTH - 1 : 0] padded_window [0:8];
    
    logic flushing;
    logic internal_valid;
    logic [4:0] valid_pipe; 
    logic [4:0] last_pipe;
    

    assign internal_valid = p_valid_in | flushing;
    
    logic [15:0] col_reg;
    logic [DATA_WIDTH - 1 : 0] p_in_reg;
    
    always_ff @(posedge aclk) begin
        if(!aresetn) begin
            col_counter <= 0;
            row_counter <= 0;
            out_col <= 0;
            out_row <= 0;
            output_active <= 0;
            col_reg <= 0;
            p_in_reg <= 0;
            for(int i = 0; i < 9; i++) v_window[i] <= 0;
        end else begin
            

            if (internal_valid) begin
                v_window[8] <= p_in;
                v_window[7] <= line_buffer[0][col_counter];
                v_window[6] <= line_buffer[1][col_counter];
                v_window[5] <= line_buffer[2][col_counter];
                v_window[4] <= line_buffer[3][col_counter];
                v_window[3] <= line_buffer[4][col_counter];
                v_window[2] <= line_buffer[5][col_counter];
                v_window[1] <= line_buffer[6][col_counter];
                v_window[0] <= line_buffer[7][col_counter];
                
                col_reg <= col_counter;
                p_in_reg <= p_in;
                
                line_buffer[0][col_reg] <= p_in_reg;
                line_buffer[1][col_reg] <= v_window[7];
                line_buffer[2][col_reg] <= v_window[6];
                line_buffer[3][col_reg] <= v_window[5];
                line_buffer[4][col_reg] <= v_window[4];
                line_buffer[5][col_reg] <= v_window[3];
                line_buffer[6][col_reg] <= v_window[2];
                line_buffer[7][col_reg] <= v_window[1];
            end
            

            if (flushing && last_pipe[0]) begin
                col_counter <= 0;
                row_counter <= 0;
                out_col <= 0;
                out_row <= 0;
                output_active <= 0;
            end else if (internal_valid) begin
                if(col_counter == width - 1) begin
                    col_counter <= 0;
                    if(row_counter == height - 1) begin
                        row_counter <= 0;
                    end else begin
                        row_counter <= row_counter + 1;
                    end
                end else begin
                    col_counter <= col_counter + 1;
                end
                
                if (row_counter == 4 && col_counter == 0) begin
                    output_active <= 1;
                end
                
                if (output_active) begin
                    if (out_col == width - 1) begin
                        out_col <= 0;
                        if (out_row == height - 1) begin
                            out_row <= 0;
                            output_active <= 0; 
                        end else begin
                            out_row <= out_row + 1;
                        end
                    end else begin
                        out_col <= out_col + 1;
                    end
                end
            end
            
        end
    end
    
    always_comb begin
        padded_window = v_window;
        
        case (out_row)
            16'd0 : begin
                padded_window[3] = v_window[4];
                padded_window[2] = v_window[4];
                padded_window[1] = v_window[4];
                padded_window[0] = v_window[4];
            end
            16'd1 : begin
                padded_window[2] = v_window[3];
                padded_window[1] = v_window[3];
                padded_window[0] = v_window[3];
            end
            16'd2 : begin
                padded_window[1] = v_window[2];
                padded_window[0] = v_window[2];
            end
            16'd3 : begin
                padded_window[0] = v_window[1];
            end
            (height - 1) : begin
                padded_window[8 - 3] = v_window[4];
                padded_window[8 - 2] = v_window[4];
                padded_window[8 - 1] = v_window[4];
                padded_window[8] = v_window[4];
            end
            (height - 2) : begin
                padded_window[8 - 2] = v_window[5];
                padded_window[8 - 1] = v_window[5];
                padded_window[8] = v_window[5];
            end
            (height - 3) : begin
                padded_window[8 - 1] = v_window[6];
                padded_window[8] = v_window[6];
            end
            (height - 4) : begin
                padded_window[8] = v_window[7];
            end
        endcase
    end
    
    // Mathematics
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
    
    
    
    // Flushing
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            flushing <= 0;
        end else begin
            if (p_valid_in && p_last_in) begin
                flushing <= 1;
            end 
            else begin 
                if (flushing && last_pipe[0]) begin
                    flushing <= 0;
                end
            end
        end
    end
    
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            valid_pipe <= 0;
            last_pipe <= 0;
        end else begin
            if (internal_valid) begin
                valid_pipe[4] <= output_active;
                valid_pipe[3] <= valid_pipe[4];
                valid_pipe[2] <= valid_pipe[3];
                valid_pipe[1] <= valid_pipe[2];
                valid_pipe[0] <= valid_pipe[1];
                
                if (output_active && out_row == height - 1 && out_col == width - 1)
                    last_pipe[4] <= 1'b1;
                else
                    last_pipe[4] <= 1'b0;
                    
                last_pipe[3] <= last_pipe[4];
                last_pipe[2] <= last_pipe[3];
                last_pipe[1] <= last_pipe[2];
                last_pipe[0] <= last_pipe[1];
            end
        end
    end
    
    assign p_valid_out = valid_pipe[0] & internal_valid;
    assign p_last_out  = last_pipe[0] & internal_valid;
    
endmodule
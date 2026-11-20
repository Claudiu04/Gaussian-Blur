`timescale 1ns / 1ps

//Gaussian Blur

module blur #(

    parameter DATA_WIDTH = 32,
    parameter MAX_IMAGE_WIDTH = 3840

    )(

    input logic aclk, aresetn,

    input logic [DATA_WIDTH - 1 : 0] s_axis_tdata,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    input logic s_axis_tlast,
    
    output logic [DATA_WIDTH - 1 : 0] m_axis_tdata,
    output logic m_axis_tvalid,
    input logic m_axis_tready,
    output logic m_axis_tlast,
    
    input logic [31 : 0] height,
    input logic [31 : 0] width,
    input logic [31 : 0] channels,
    input logic [1 : 0] kernel_size

    );
    
    logic [7 : 0] R, G, B;
    logic [7 : 0] R_out, G_out, B_out;
    
    assign s_axis_tready = m_axis_tready;
    
    assign R = (channels == 1) ? s_axis_tdata[7:0] : s_axis_tdata[23:16];
    assign G = (channels == 1) ? 8'd0 : s_axis_tdata[15:8];
    assign B = (channels == 1) ? 8'd0 : s_axis_tdata[7:0];
    
    
    assign m_axis_tdata = (channels == 1) ?  {24'd0, R_out} : {8'd0, R_out, G_out, B_out};
    
    wire [7:0] p_out_R;
    wire p_valid_out_R;
    wire p_last_out_R;
    
    blur_horizontal #(

    .DATA_WIDTH(8),
    .MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH)

    ) blur_horizontal_R (

    .aclk(aclk),
    .aresetn(aresetn),
    .kernel_size(kernel_size),
    .width(width),
    .p_in(R),
    .p_valid_in(s_axis_tvalid),
    .p_last_in(s_axis_tlast),
    .p_out(p_out_R),
    .p_valid_out(p_valid_out_R),
    .p_last_out(p_last_out_R)
    
    );
    
    blur_vertical #(

    .DATA_WIDTH(8),
    .MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH)

    ) blur_vertical_R (

    .aclk(aclk),
    .aresetn(aresetn),
    .kernel_size(kernel_size),
    .width(width),
    .height(height),
    .p_in(p_out_R),
    .p_valid_in(p_valid_out_R),
    .p_last_in(p_last_out_R),
    .p_out(R_out),
    .p_valid_out(m_axis_tvalid),
    .p_last_out(m_axis_tlast)
    
    );
    
        wire [7:0] p_out_G;
    wire p_valid_out_G;
    wire p_last_out_G;
    
    blur_horizontal #(

    .DATA_WIDTH(8),
    .MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH)

    ) blur_horizontal_G (

    .aclk(aclk),
    .aresetn(aresetn),
    .kernel_size(kernel_size),
    .width(width),
    .p_in(G),
    .p_valid_in(s_axis_tvalid),
    .p_last_in(s_axis_tlast),
    .p_out(p_out_G),
    .p_valid_out(p_valid_out_G),
    .p_last_out(p_last_out_G)
    
    );
    
    blur_vertical #(

    .DATA_WIDTH(8),
    .MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH)

    ) blur_vertical_G (

    .aclk(aclk),
    .aresetn(aresetn),
    .kernel_size(kernel_size),
    .width(width),
    .height(height),
    .p_in(p_out_G),
    .p_valid_in(p_valid_out_G),
    .p_last_in(p_last_out_G),
    .p_out(G_out),
    .p_valid_out(),
    .p_last_out()
    
    );
    
        wire [7:0] p_out_B;
    wire p_valid_out_B;
    wire p_last_out_B;
    
    blur_horizontal #(

    .DATA_WIDTH(8),
    .MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH)

    ) blur_horizontal_B (

    .aclk(aclk),
    .aresetn(aresetn),
    .kernel_size(kernel_size),
    .width(width),
    .p_in(B),
    .p_valid_in(s_axis_tvalid),
    .p_last_in(s_axis_tlast),
    .p_out(p_out_B),
    .p_valid_out(p_valid_out_B),
    .p_last_out(p_last_out_B)
    
    );
    
    blur_vertical #(

    .DATA_WIDTH(8),
    .MAX_IMAGE_WIDTH(MAX_IMAGE_WIDTH)

    ) blur_vertical_B (

    .aclk(aclk),
    .aresetn(aresetn),
    .kernel_size(kernel_size),
    .width(width),
    .height(height),
    .p_in(p_out_B),
    .p_valid_in(p_valid_out_B),
    .p_last_in(p_last_out_B),
    .p_out(B_out),
    .p_valid_out(),
    .p_last_out()
    
    );
    
    
    
endmodule

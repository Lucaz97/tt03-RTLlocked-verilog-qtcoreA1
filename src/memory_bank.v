`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: New York University
// Engineer: ChatGPT GPT-4 Mar 23 version; Hammond Pearce (prompting)
// 
// Last Edited Date: 04/19/2023
//////////////////////////////////////////////////////////////////////////////////

module memory_bank #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8,
    parameter MEM_SIZE = 15, // Reduce memory size by 1 to accommodate IO
    parameter IO_ADDR = MEM_SIZE
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_WIDTH-1:0] address,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire write_enable,
    output reg [DATA_WIDTH-1:0] data_out,
    input wire scan_enable,
    input wire scan_in,
    output wire scan_out,
    input wire btn_in, // Button input
    output wire [6:0] led_out, // 7-bit LED output
    output wire [15:0] locking_key
);

    // Generate an array of shift registers for the memory
    wire [DATA_WIDTH-1:0] mem_data_out [0:MEM_SIZE-1];
    wire mem_scan_out [0:MEM_SIZE-1]; 

    genvar i;
    generate
        for (i = 0; i < MEM_SIZE; i = i + 1) begin : memory
            shift_register #(
                .WIDTH(DATA_WIDTH)
            ) mem_cell (
                .clk(clk),
                .rst(rst),
                .enable(write_enable && (address == i)),
                .data_in(data_in),
                .data_out(mem_data_out[i]),
                .scan_enable(scan_enable),
                .scan_in(i == 0 ? scan_in : mem_scan_out[i-1]),
                .scan_out(mem_scan_out[i])
            );
        end
    endgenerate

    // IO shift registers
    wire [6:0] led_data_out;
    wire btn_data_out;
    wire io_scan_out; // New wire to connect scan_out of btn_shift_register to scan_in of led_shift_register
    
    shift_register #(
        .WIDTH(1)
    ) btn_shift_register (
        .clk(clk),
        .rst(rst),
        .enable(1'b1), // Enable the btn_shift_register, always read the status of the button input
        .data_in(btn_in),
        .data_out(btn_data_out),
        .scan_enable(scan_enable),
        .scan_in(mem_scan_out[MEM_SIZE-1]), // Connect the scan_in to the last memory cell scan_out
        .scan_out(io_scan_out) // Connect the new wire to the scan_out
    );

    wire led_scan_out;
    shift_register #(
        .WIDTH(7)
    ) led_shift_register (
        .clk(clk),
        .rst(rst),
        .enable(write_enable && (address == IO_ADDR)),
        .data_in(data_in[7:1]), // Read from upper 7 bits of data_in
        .data_out(led_data_out),
        .scan_enable(scan_enable),
        .scan_in(io_scan_out), // Connect the new wire to the scan_in
        .scan_out(led_scan_out) // Connect the scan_out to the top-level module
    );

    //locking  key register
    shift_register #(
        .WIDTH(16)
    ) locking_key_shift_register (
        .clk(clk),
        .rst(rst),
        .enable(1'b0), // This is only accessible via scan chain
        .data_in(8'b0), //doesn't matter what this is
        .data_out(locking_key),
        .scan_enable(scan_enable),
        .scan_in(led_scan_out), // Connect the scan_in to the last memory cell scan_out
        .scan_out(scan_out) // Connect the new wire to the scan_out
    );

    // Read operation
    always @(*) begin
        if (address < MEM_SIZE) begin
            data_out = mem_data_out[address];
        end else case (address)
            IO_ADDR: data_out = {led_data_out, btn_data_out}; // Place btn_data_out at the LSB
            default: data_out = 8'b00000001; // Return "00000001" for all other memory addresses outside the range
        endcase
    end


    // Assign LED output
    assign led_out = led_data_out;

endmodule
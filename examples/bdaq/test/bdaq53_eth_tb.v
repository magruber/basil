/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Physics Institute, University of Bonn
 * ------------------------------------------------------------
 */

`timescale 1ps / 1ps

`include "firmware/src/bdaq53_eth_core.v"
`include "bram_fifo/bram_fifo.v"
`include "bram_fifo/bram_fifo_core.v"
`include "utils/reset_gen.v"
`include "utils/fifo_32_to_8.v"
`include "utils/generic_fifo.v"
`include "utils/clock_multiplier.v"
`include "utils/clock_divider.v"
`include "utils/rbcp_to_bus.v"
`include "utils/bus_to_ip.v"


module tb (
    input wire          BUS_CLK,
    input wire          BUS_RST,
    input wire  [31:0]  BUS_ADD,
    inout wire  [31:0]  BUS_DATA,
    input wire          BUS_RD,
    input wire          BUS_WR,
    output wire         BUS_BYTE_ACCESS
);

localparam FIFO_BASEADDR = 32'h8000;
localparam FIFO_HIGHADDR = 32'h9000-1;

localparam FIFO_BASEADDR_DATA = 32'h8000_0000;
localparam FIFO_HIGHADDR_DATA = 32'h9000_0000;

assign BUS_BYTE_ACCESS = BUS_ADD < 32'h8000_0000 ? 1'b1 : 1'b0;

localparam RESET_DELAY = 5000;
localparam PLL_LOCK_DELAY = 1e6;

reg LOCKED;
initial begin
    LOCKED = 1'b0;
    #(PLL_LOCK_DELAY) LOCKED = 1'b1;
end

reg RESET_N;
initial begin
    RESET_N = 1'b0;
    #(RESET_DELAY) RESET_N = 1'b1;
end


// -------  USER MODULES  ------- //
wire FIFO_FULL, FIFO_WRITE;
wire [31:0] FIFO_DATA;
bram_fifo #(
    .BASEADDR(FIFO_BASEADDR),
    .HIGHADDR(FIFO_HIGHADDR),
    .BASEADDR_DATA(FIFO_BASEADDR_DATA),
    .HIGHADDR_DATA(FIFO_HIGHADDR_DATA),
    .ABUSWIDTH(32)
) i_out_fifo (
    .BUS_CLK(BUS_CLK),
    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .FIFO_READ_NEXT_OUT(),
    .FIFO_EMPTY_IN(!FIFO_WRITE),
    .FIFO_DATA(FIFO_DATA),

    .FIFO_NOT_EMPTY(),
    .FIFO_FULL(FIFO_FULL),
    .FIFO_NEAR_FULL(),
    .FIFO_READ_ERROR()
);


bdaq53_eth_core i_bdaq53_eth_core(
    .RESET_N(RESET_N),

    // clocks from PLL
    .BUS_CLK(BUS_CLK),
    .PLL_LOCKED(LOCKED),

    .BUS_RST(BUS_RST),
    .BUS_ADD(BUS_ADD),
    .BUS_DATA(BUS_DATA),
    .BUS_RD(BUS_RD),
    .BUS_WR(BUS_WR),

    .fifo_full(FIFO_FULL),
    .FIFO_DATA(FIFO_DATA),
    .FIFO_WRITE(FIFO_WRITE),

    .GPIO()
    );


initial begin
    $dumpfile("/tmp/bdaq_eth.vcd");
    $dumpvars(0);
end

endmodule

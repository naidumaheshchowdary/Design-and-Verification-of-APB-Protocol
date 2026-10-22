module APB_Slave #(
  parameter ADDR_WIDTH   = 32,
  parameter DATA_WIDTH   = 32,
  parameter MEM_DEPTH    = 64,   // number of words
  parameter WAIT_STATES  = 2     // 0 = zero-wait-state slave
)(
  input  logic                  PCLK,
  input  logic                  PRESETn,
  input  logic                  PSELx,
  input  logic                  PENABLE,
  input  logic                  PWRITE,
  input  logic [ADDR_WIDTH-1:0] PADDR,
  input  logic [DATA_WIDTH-1:0] PWDATA,
  output logic [DATA_WIDTH-1:0] PRDATA,
  output logic                  PREADY,
  output logic                  PSLVERR
);

  localparam WORD_LSB = $clog2(DATA_WIDTH/8);   // 2 for 32-bit data

  logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

  logic [ADDR_WIDTH-1:0] word_addr;
  logic                  addr_err;
  logic                  setup_phase, access_phase;
  logic [7:0]            wait_cnt;

  assign word_addr    = PADDR >> WORD_LSB;
  assign addr_err     = (word_addr >= MEM_DEPTH);

  assign setup_phase  = PSELx && !PENABLE;
  assign access_phase = PSELx &&  PENABLE;

  // Wait-state counter: reload in setup, count down in access
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)
      wait_cnt <= '0;
    else if (setup_phase)
      wait_cnt <= WAIT_STATES;
    else if (access_phase && wait_cnt != 0)
      wait_cnt <= wait_cnt - 1;
  end

  // Ready when the wait states have been used up
  assign PREADY  = access_phase && (wait_cnt == 0);

  // Error is only meaningful in the last cycle of the access phase
  assign PSLVERR = PREADY && addr_err;

  // Read data (combinational, valid while PREADY is high)
  assign PRDATA  = (access_phase && !PWRITE && !addr_err) ? mem[word_addr] : '0;

  // Write on the last cycle of the access phase
  always_ff @(posedge PCLK) begin
    if (PREADY && PWRITE && !addr_err)
      mem[word_addr] <= PWDATA;
  end

endmodule










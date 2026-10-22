module APB_Master #(parameter ADDR_WIDTH = 32,
                   parameter DATA_WIDTH = 32)(
  input logic PCLK,
  input logic PRESETn,
  input logic [DATA_WIDTH-1:0] PRDATA,
  input logic PSLVERR,
  input logic PREADY,
  
  input logic Transfer,
  input logic [ADDR_WIDTH-1:0] addr, 
  input logic [DATA_WIDTH-1:0] wdata,
  input logic write,
  output logic [ADDR_WIDTH-1:0] PADDR,
  output logic [DATA_WIDTH-1:0] rdata,
  output logic done, error,
  
  output logic PSELx,
  output logic PENABLE,
  output logic PWRITE,
  output logic [DATA_WIDTH-1:0] PWDATA
    
);

  typedef enum bit [1:0] {Idle = 2'd0, Setup, Access_Phase} State;
  State CS, NS;
  
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) CS <= Idle;
    else CS <= NS;
  end
  
  always_comb begin
    case(CS)
      Idle: NS = Transfer? Setup: Idle;
      Setup: NS = Access_Phase;
      Access_Phase: NS = PREADY? (Transfer? Setup:Idle) :Access_Phase;
      default NS = Idle;
    endcase
    
  end
  
  always_ff @(posedge PCLK or negedge PRESETn) 
    begin
      if (!PRESETn) begin
        PSELx <= 0;
        PENABLE <= 0;
        PADDR <= 0;
        PWDATA <= 0;
        PWRITE <= 0;
        
      end
      
      else begin
        case (NS)
          Idle : begin
            PSELx <= 1'b0;
            PENABLE <= 1'b0;
            end
          Setup : begin
            PSELx <= 1'b1;
            PENABLE <= 1'b0;
            PADDR <= addr;
            PWRITE <= write;
            PWDATA <= wdata;
          end
          Access_Phase : begin
            PSELx <= 1'b1;
            PENABLE <= 1'b1;
          end
          default: begin
            PSELx <= 1'b0;
            PENABLE <= 1'b0;
          end
        endcase
      end
    end
   // error / done capture checking
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      rdata <= '0;
      error <= 1'b0;
      done  <= 1'b0;
    end else begin
      done <= 1'b0;
      if (PSELx && PENABLE && PREADY) begin
        done  <= 1'b1;
        error <= PSLVERR;
        if (!PWRITE) rdata <= PRDATA;
      end
    end
  end
  
endmodule





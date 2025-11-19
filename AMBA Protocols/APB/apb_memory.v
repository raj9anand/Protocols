
//==============================================================
// APB MEMORY SLAVE
//==============================================================
module apb_memory(
    input         pclk,
    input         prst,         // active-low reset
    input  [31:0] paddr,
    input         pselx,
    input         penable,
    input         pwrite,
    input  [31:0] pwdata,
    output reg    pready,
    output reg    pslverr,
    output reg [31:0] prdata,
    output reg [31:0] temp
);

  // simple memory 32 x 32
  reg [31:0] mem [0:31];

  // APB state machine
  typedef enum reg [1:0] {
    IDLE   = 2'b00,
    SETUP  = 2'b01,
    ACCESS = 2'b10
  } apb_state_t;

  apb_state_t present_state, next_state;

  //==============================================================
  // STATE REGISTER
  //==============================================================
  always @(posedge pclk or negedge prst)
  begin
    if (!prst) begin
      present_state <= IDLE;
    end else begin
      present_state <= next_state;
    end
  end

  //==============================================================
  // NEXT STATE LOGIC + OUTPUTS
  //==============================================================
  always @(*)
  begin
    // default outputs (VERY IMPORTANT)
    pready   = 0;
    pslverr  = 0;
    prdata   = 0;
    temp     = 0;
    next_state = present_state;

    case (present_state)

      //------------------------------------------------------------
      // IDLE PHASE
      //------------------------------------------------------------
      IDLE: begin
        if (pselx && !penable)
          next_state = SETUP;
      end

      //------------------------------------------------------------
      // SETUP PHASE
      //------------------------------------------------------------
      SETUP: begin
        if (pselx && penable) begin
          pready = 1;
          next_state = ACCESS;
        end else begin
          next_state = IDLE;
        end
      end

      //------------------------------------------------------------
      // ACCESS PHASE
      //------------------------------------------------------------
      ACCESS: begin
        pready = 1;

        if (pwrite) begin
          mem[paddr[4:0]] = pwdata;     // restrict address to 0–31
          temp = mem[paddr[4:0]];
        end else begin
          prdata = mem[paddr[4:0]];
          temp   = mem[paddr[4:0]];
        end

        // after access, go back to idle
        if (!pselx || !penable)
          next_state = IDLE;
      end

    endcase
  end

endmodule

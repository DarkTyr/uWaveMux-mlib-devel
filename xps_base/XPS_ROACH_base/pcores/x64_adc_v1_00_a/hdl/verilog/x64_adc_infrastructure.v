module x64_adc_infrastructure(
    input        adc_clk_n,
    input        adc_clk_p,

    output       adc_clk0,
    output       adc_clk90,
    output       adc_clk180,
    output       adc_clk270,

    input  [7:0] in_0_n, 
    input  [7:0] in_0_p, 
    input        fc_0_n,
    input        fc_0_p,
    input  [7:0] in_1_n, 
    input  [7:0] in_1_p, 
    input        fc_1_n,
    input        fc_1_p,
    input  [7:0] in_2_n, 
    input  [7:0] in_2_p, 
    input        fc_2_n,
    input        fc_2_p,
    input  [7:0] in_3_n, 
    input  [7:0] in_3_p, 
    input        fc_3_n,
    input        fc_3_p,
    input  [7:0] in_4_n, 
    input  [7:0] in_4_p, 
    input        fc_4_n,
    input        fc_4_p,
    input  [7:0] in_5_n, 
    input  [7:0] in_5_p, 
    input        fc_5_n,
    input        fc_5_p,
    input  [7:0] in_6_n, 
    input  [7:0] in_6_p, 
    input        fc_6_n,
    input        fc_6_p,
    input  [7:0] in_7_n, 
    input  [7:0] in_7_p, 
    input        fc_7_n,
    input        fc_7_p,

    output [7:0] in_rise_0,
    output       fc_rise_0,
    output [7:0] in_rise_1,
    output       fc_rise_1,
    output [7:0] in_rise_2,
    output       fc_rise_2,
    output [7:0] in_rise_3,
    output       fc_rise_3,
    output [7:0] in_rise_4,
    output       fc_rise_4,
    output [7:0] in_rise_5,
    output       fc_rise_5,
    output [7:0] in_rise_6,
    output       fc_rise_6,
    output [7:0] in_rise_7,
    output       fc_rise_7,

    output [7:0] in_fall_0,
    output       fc_fall_0,
    output [7:0] in_fall_1,
    output       fc_fall_1,
    output [7:0] in_fall_2,
    output       fc_fall_2,
    output [7:0] in_fall_3,
    output       fc_fall_3,
    output [7:0] in_fall_4,
    output       fc_fall_4,
    output [7:0] in_fall_5,
    output       fc_fall_5,
    output [7:0] in_fall_6,
    output       fc_fall_6,
    output [7:0] in_fall_7,
    output       fc_fall_7,

    input        dly_clk,
    input  [7:0] dly_rst,
    input  [7:0] dly_en,
    input  [7:0] dly_inc_dec_n,

    input        dcm_reset,
    output       dcm_locked,
    output       fab_clk
  );
  
  parameter ADC_BIT_CLK_PERIOD = 3.3;

  /*********** Buffers and delay for input data and clock frame signals */

  /* 8*8 channels + a frame clk per channel */
  localparam NINST = 9*8;
  wire [NINST-1:0] in_ibufds;

  IBUFDS ibufds_in[NINST-1:0] (
    .I  ({fc_7_p, in_7_p, fc_6_p, in_6_p, fc_5_p, in_5_p, fc_4_p, in_4_p,
          fc_3_p, in_3_p, fc_2_p, in_2_p, fc_1_p, in_1_p, fc_0_p, in_0_p}), 
    .IB ({fc_7_n, in_7_n, fc_6_n, in_6_n, fc_5_n, in_5_n, fc_4_n, in_4_n,
          fc_3_n, in_3_n, fc_2_n, in_2_n, fc_1_n, in_1_n, fc_0_n, in_0_n}), 
    .O  (in_ibufds)
  );

  wire [NINST-1:0] dly_en_int;
  wire [NINST-1:0] dly_inc_dec_n_int;
  wire [NINST-1:0] dly_rst_int;
  wire [NINST-1:0] in_iodelay;

  assign dly_en_int     = {{9{dly_en[7]}}, {9{dly_en[6]}}, {9{dly_en[5]}}, {9{dly_en[4]}},
                           {9{dly_en[3]}}, {9{dly_en[2]}}, {9{dly_en[1]}}, {9{dly_en[0]}}};

  assign dly_inc_dec_n_int = {{9{dly_inc_dec_n[7]}}, {9{dly_inc_dec_n[6]}},
                              {9{dly_inc_dec_n[5]}}, {9{dly_inc_dec_n[4]}},
                              {9{dly_inc_dec_n[3]}}, {9{dly_inc_dec_n[2]}},
                              {9{dly_inc_dec_n[1]}}, {9{dly_inc_dec_n[0]}}};

  assign dly_rst_int    = {{9{dly_rst[7]}}, {9{dly_rst[6]}}, {9{dly_rst[5]}}, {9{dly_rst[4]}},
                           {9{dly_rst[3]}}, {9{dly_rst[2]}}, {9{dly_rst[1]}}, {9{dly_rst[0]}}};

  IODELAY #(
    .DELAY_SRC        ("I"),
    .IDELAY_TYPE      ("VARIABLE"),
    .REFCLK_FREQUENCY (200.0)
  ) iodelay_in [NINST-1:0] (
    .C       (dly_clk),
    .CE      (dly_en_int),
    .DATAIN  (1'b0),
    .IDATAIN (in_ibufds),
    .INC     (dly_inc_dec_n_int),
    .ODATAIN (),
    .RST     (dly_rst_int),
    .T       (1'b0),
    .DATAOUT (in_iodelay)
  );

  wire [NINST-1:0] in_rise;
  wire [NINST-1:0] in_fall;

  IDDR #(
    .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"),
    .INIT_Q1 (1'b0),
    .INIT_Q2 (1'b0),
    .SRTYPE ("SYNC")
  ) IDDR_qdrq [NINST-1:0] (
    .C  (adc_clk0),
    .CE (1'b1),
    .D  (in_iodelay),
    .R  (1'b0),
    .S  (1'b0),
    .Q1 (in_rise),
    .Q2 (in_fall)
  );

  assign in_rise_0 = in_rise[7:0];
  assign fc_rise_0 = in_rise[8];
  assign in_rise_1 = in_rise[16:9];
  assign fc_rise_1 = in_rise[17];
  assign in_rise_2 = in_rise[25:18];
  assign fc_rise_2 = in_rise[26];
  assign in_rise_3 = in_rise[34:27];
  assign fc_rise_3 = in_rise[35];
  assign in_rise_4 = in_rise[43:36];
  assign fc_rise_4 = in_rise[44];
  assign in_rise_5 = in_rise[52:45];
  assign fc_rise_5 = in_rise[53];
  assign in_rise_6 = in_rise[61:54];
  assign fc_rise_6 = in_rise[62];
  assign in_rise_7 = in_rise[70:63];
  assign fc_rise_7 = in_rise[71];

  assign in_fall_0 = in_fall[7:0];
  assign fc_fall_0 = in_fall[8];
  assign in_fall_1 = in_fall[16:9];
  assign fc_fall_1 = in_fall[17];
  assign in_fall_2 = in_fall[25:18];
  assign fc_fall_2 = in_fall[26];
  assign in_fall_3 = in_fall[34:27];
  assign fc_fall_3 = in_fall[35];
  assign in_fall_4 = in_fall[43:36];
  assign fc_fall_4 = in_fall[44];
  assign in_fall_5 = in_fall[52:45];
  assign fc_fall_5 = in_fall[53];
  assign in_fall_6 = in_fall[61:54];
  assign fc_fall_6 = in_fall[62];
  assign in_fall_7 = in_fall[70:63];
  assign fc_fall_7 = in_fall[71];


  /*********** Buffers and DCM for Clock input */

  wire adc_clk_ibufds;
  IBUFDS ibufds_clk(
    .I  (adc_clk_p),
    .IB (adc_clk_n),
    .O  (adc_clk_ibufds)
  );

  wire adc_clk_dcm;
  wire adc_clk90_dcm;
  wire adc_clk180_dcm;
  wire adc_clk270_dcm;
  
  DCM #(
    .CLK_FEEDBACK          ("1X"),
    .CLKDV_DIVIDE          (2.000000),
    .CLKFX_DIVIDE          (6),
    .CLKFX_MULTIPLY        (4),
    .CLKIN_PERIOD          (ADC_BIT_CLK_PERIOD),
    .CLKOUT_PHASE_SHIFT    ("VARIABLE_CENTER"),
    .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
    .DFS_FREQUENCY_MODE    ("HIGH"),
    .DLL_FREQUENCY_MODE    ("HIGH"),
    .FACTORY_JF            (16'hC080),
    .PHASE_SHIFT           (0),
    .STARTUP_WAIT          (1'b0)
  ) dcm_inst (
    .CLKFB                 (adc_clk0),
    .CLKIN                 (adc_clk_ibufds),
    .DSSEN                 (0),
    .PSCLK                 (1'b0),
    .PSEN                  (1'b0),
    .PSINCDEC              (1'b0),
    .RST                   (dcm_reset),
    .CLKDV                 (),
    .CLKFX                 (fab_clk),
    .CLKFX180              (),
    .CLK0                  (adc_clk_dcm),
    .CLK2X                 (),
    .CLK2X180              (),
    .CLK90                 (adc_clk90_dcm),
    .CLK180                (adc_clk180_dcm),
    .CLK270                (adc_clk270_dcm),
    .LOCKED                (dcm_locked),
    .PSDONE                (),
    .STATUS                ()
  );

  BUFG bufg[3:0] (
    .I ({adc_clk_dcm, adc_clk90_dcm, adc_clk180_dcm, adc_clk270_dcm}),
    .O ({adc_clk0,    adc_clk90,     adc_clk180,     adc_clk270})
  );


endmodule

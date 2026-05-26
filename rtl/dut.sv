//---------------------------------------------------------------------------
// DUT - Transformer project 
//---------------------------------------------------------------------------
`include "common.vh"

module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output reg dut_ready                   ,

//---------------------------------------------------------------------------
//input SRAM interface
  output reg                           dut__tb__sram_input_write_enable  ,
  output reg [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_write_address ,
  output reg [`SRAM_DATA_RANGE     ]   dut__tb__sram_input_write_data    ,
  output reg [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_input_read_data     ,     

//weight SRAM interface
  output reg                           dut__tb__sram_weight_write_enable  ,
  output reg [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_write_address ,
  output reg [`SRAM_DATA_RANGE     ]   dut__tb__sram_weight_write_data    ,
  output reg [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_weight_read_data     ,     

//result SRAM interface
  output reg                           dut__tb__sram_result_write_enable  ,
  output reg [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_write_address ,
  output reg [`SRAM_DATA_RANGE     ]   dut__tb__sram_result_write_data    ,
  output reg [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_result_read_data    ,       

//scratchpad SRAM interface
  output reg                           dut__tb__sram_scratchpad_write_enable  ,
  output reg [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_write_address ,
  output reg [`SRAM_DATA_RANGE     ]   dut__tb__sram_scratchpad_write_data    ,
  output reg [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_scratchpad_read_data  

);


// Internal signals for computation
reg [63:0] accum_result, accum_result1; // Accumulator for MAC results
reg [63:0] enable_mac, enable_mac1; // Enable mac to compute the results
wire [63:0] mac_result_z, mac_result_z1;  // Output of MAC operation
reg inst_tc = 1'b0; // Two's complement control: 0 = Unsigned 1 = Signed
reg [1:0] mat_accum = 1'b0;

// State machine for control flow
reg [3:0] state;
localparam IDLE = 4'd0, MATRIX_DIM_REQUEST = 4'd1, READ_INPUTS = 4'd2, READ_RAWCOL = 4'd3, COMPUTE = 4'd4, ACCUM_RESULT = 4'd5, WRITE_RESULTS = 4'd6, SCORE_MAT_S_REQ = 4'd7, SCORE_WRITE_RESULTS = 4'd8, ATTENTION_MAT_REQ = 4'd9, ATTENTION_MAT_WRITE_RESULTS = 4'd10, DONE = 4'd11;

// Matrix dimensions and address tracking
reg [15:0] matrixA_rows, matrixA_cols, matrixB_rows, matrixB_cols;
reg [15:0] input_row, input_col, weight_row, weight_col;

reg [2:0] i_matrix = 3'b0;

/*
    
============Inputs================    
I Matrix --> MatrixA_Rows X MatrixA_Cols
WQ Matrix --> MatrixB_Rows X MatrixB_Cols
WK Matrix --> MatrixB_Rows X MatrixB_Cols
WV Matrix --> MatrixB_Rows X MatrixB_Cols
============Outputs================
Q = I X WQ --> Stored in result SRAM
K = I X WK --> Stored in result SRAM
V = I X WV --> Stored in result SRAM and scratchpad SRAM

Q Matrix --> MatrixA_Rows X MatrixB_Cols
K Matrix --> MatrixA_Rows X MatrixB_Cols
V Matrix --> MatrixA_Rows X MatrixB_Cols

KT = Transpose(K) --> Stored in scratchpad SRAM    

KT Matrix --> MatrixB_Cols X MatrixA_Rows   
    
S = Q X KT --> Stored in result SRAM

S Matrix --> MatrixA_Rows X MatrixA_Rows

Z = S X V --> Final result Z stored in result SRAM

Z Matrix --> MatrixA_Rows X MatrixB_Cols    

===================================    
*/

// DUT ready signal control
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        // Reset all signals and set to IDLE state
        state <= IDLE;
        dut_ready <= 1'b1;
        input_row <= 0;
        input_col <= 0;
        weight_col <= 0;
        weight_row <= 0;
                
        dut__tb__sram_input_write_enable <= 1'b0;
        dut__tb__sram_weight_write_enable <= 1'b0;
        accum_result <= 0;
        accum_result1 <= 0;
        //enable_mac <= 64'hFFFF_FFFF_FFFF_FFFF;
        enable_mac <= 64'h0;
        enable_mac1 <= 64'h0;

        mat_accum <= 0;
        i_matrix <= 0;
    end else begin
        case (state)
            IDLE: begin
                if (dut_valid) begin
                    dut_ready <= 1'b0;
                    //state <= READ_INPUTS;
                    state <= MATRIX_DIM_REQUEST;
                    input_row <= 0;
                    input_col <= 0;
                    weight_col <= 0;
                    weight_row <= 0;
                    accum_result <= 0;
                    accum_result1 <= 0;
                    mat_accum <= 0;
                    i_matrix <= 0;
                    dut__tb__sram_input_write_enable <= 1'b0;
                    dut__tb__sram_weight_write_enable <= 1'b0;
                end
            end
            MATRIX_DIM_REQUEST: begin
                dut__tb__sram_input_read_address <= 0;
                dut__tb__sram_weight_read_address <= 0;
                // Move to READ_INPUTS state
                state <= READ_INPUTS;
            end
            READ_INPUTS: begin
                // Move to READ_RAWCOL state
                state <= READ_RAWCOL;
            end
            READ_RAWCOL: begin
                state <= COMPUTE;
                // Read matrix A dimensions from input SRAM
                if (input_row == 0 && input_col == 0) begin
                    matrixA_rows <= tb__dut__sram_input_read_data[31:16];
                    matrixA_cols <= tb__dut__sram_input_read_data[15:0];
                end
                // Read matrix B dimensions from weight SRAM
                if (weight_row == 0 && weight_col == 0) begin
                    matrixB_rows <= tb__dut__sram_weight_read_data[31:16];
                    matrixB_cols <= tb__dut__sram_weight_read_data[15:0];
                end
            end
            COMPUTE: begin
                // Matrix multiplication using MAC
                if(i_matrix != 3'b11) begin
                    if(input_row < matrixA_rows) begin
                        if(input_col < matrixA_cols) begin
                            dut__tb__sram_input_read_address <= input_row * matrixA_cols + input_col + 1;
                            input_col <= input_col + 1;
                            state <= ACCUM_RESULT;
                            //enable_mac <= 64'hFFFF_FFFF_FFFF_FFFF;
                        end
                        else begin
                            input_col <= 0;
                            state <= WRITE_RESULTS;
                        end
                    end
                    else begin
                        state <= WRITE_RESULTS;
                        input_col <= 0;
                    end
                    if(weight_col < matrixB_cols) begin
                        if(weight_row < matrixB_rows) begin
                            dut__tb__sram_weight_read_address <= (weight_col * matrixB_rows) + weight_row + 1 + (i_matrix * (matrixB_rows * matrixB_cols));
                            weight_row <= weight_row + 1;
                            state <= ACCUM_RESULT;
                        end else begin
                            weight_row <= 0;
                            state <= WRITE_RESULTS;
                        end
                    end
                    else begin
                        state <= WRITE_RESULTS;
                    end
                end // i_matrix != 2'b11
                else begin
                    state <= SCORE_MAT_S_REQ;
                end
            end
            ACCUM_RESULT: begin
                if(mat_accum == 2'b01) begin
                    state <= SCORE_MAT_S_REQ;
                    enable_mac1 <= 64'hFFFF_FFFF_FFFF_FFFF;
                    accum_result1 <= mac_result_z1;
                end else if(mat_accum == 2'b10) begin
                    state <= ATTENTION_MAT_REQ;
                    enable_mac1 <= 64'hFFFF_FFFF_FFFF_FFFF;
                    accum_result1 <= mac_result_z1;
                end else begin
                    state <= COMPUTE;
                    enable_mac <= 64'hFFFF_FFFF_FFFF_FFFF;
                    accum_result <= mac_result_z;
                end
            end
            WRITE_RESULTS: begin
                if(weight_col != matrixB_cols) begin
                    // Write result to SRAM
                    dut__tb__sram_result_write_enable <= 1'b1;
                    dut__tb__sram_result_write_address <= input_row * matrixB_cols + weight_col + (i_matrix * (matrixA_rows * matrixB_cols));
                    dut__tb__sram_result_write_data <= mac_result_z;
                    enable_mac <= 64'h0;
                    if(i_matrix != 2'b00) begin
                        dut__tb__sram_scratchpad_write_enable <= 1'b1;
                        dut__tb__sram_scratchpad_write_address <= input_row * matrixB_cols + weight_col + ((i_matrix-1) * (matrixA_rows * matrixB_cols));
                        dut__tb__sram_scratchpad_write_data <= mac_result_z;
                    end
                end
                if (weight_col < matrixB_cols) begin
                    if ((weight_col == matrixB_cols-1)) begin
                        weight_col <= 0;
                        i_matrix <= (input_row == matrixA_rows-1) ? i_matrix + 1 : i_matrix;
                        input_row <= (input_row == matrixA_rows-1) ? 0: input_row + 1;
                    end else begin
                        weight_col <= weight_col + 1;
                    end
                    state <= COMPUTE;
                end 
            end
            SCORE_MAT_S_REQ: begin
                //S = Q X KT --> Stored in result SRAM
                //S Matrix --> MatrixA_Rows X MatrixA_Rows                
                // Matrix multiplication using MAC
                if(input_row < matrixA_rows) begin
                    if(weight_col < matrixA_rows) begin
                        if(weight_row < matrixB_cols) begin  //weight_row is as scratchpad KT matrix rows and the dimention:MatrixB_Cols x MatrixA_rows
                            dut__tb__sram_result_write_enable <= 1'b0;
                            dut__tb__sram_scratchpad_write_enable <= 1'b0;
                            dut__tb__sram_result_read_address <= input_row * matrixB_cols + weight_row;
                            dut__tb__sram_scratchpad_read_address <= weight_col * matrixB_cols + weight_row;
                            weight_row <= weight_row + 1;
                            state <= ACCUM_RESULT;
                            mat_accum <= 2'b01;
                        end else begin
                            state <= SCORE_WRITE_RESULTS;
                        end
                    end else begin
                        state <= SCORE_WRITE_RESULTS;
                    end
                end else begin
                    state <= ATTENTION_MAT_REQ;
                    input_row <= 0;
                end
            end
            SCORE_WRITE_RESULTS: begin
                // Write result to result SRAM
                dut__tb__sram_result_write_enable <= 1'b1;
                dut__tb__sram_result_write_address <= input_row * matrixA_rows + weight_col + (i_matrix * (matrixA_rows * matrixB_cols));
                dut__tb__sram_result_write_data <= mac_result_z1;
                enable_mac1 <= 64'h0;

                if (input_row < matrixA_rows) begin
                    if(weight_row == matrixB_cols) begin
                        if(weight_col == matrixA_rows - 1) begin
                            input_row <= input_row + 1;
                            weight_col <= 0;
                        end
                        else begin
                            weight_col <= weight_col + 1;
                        end
                        weight_row <= 0;
                    end
                    state <= SCORE_MAT_S_REQ;
                end
            end
            ATTENTION_MAT_REQ: begin
                //S Matrix --> MatrixA_Rows X MatrixA_Rows
                //V Matrix --> MatrixA_Rows X MatrixB_Cols
                //Z = S X V --> Final result Z stored in result SRAM
                //Z Matrix --> MatrixA_Rows X MatrixB_Cols 
                
                // Matrix multiplication using MAC
                if(input_row < matrixA_rows) begin
                    if(input_col < matrixA_rows) begin
                        dut__tb__sram_result_write_enable <= 1'b0;
                        dut__tb__sram_result_read_address <= input_row * matrixA_rows + input_col + (i_matrix * (matrixA_rows * matrixB_cols));
                        input_col <= input_col + 1;
                        state <= ACCUM_RESULT;
                        mat_accum <= 2'b10;
                    end
                    else begin
                        input_col <= 0;
                        state <= ATTENTION_MAT_WRITE_RESULTS;
                    end
                end
                else begin
                    state <= DONE;
                end
                if(weight_col < matrixB_cols) begin
                    if(weight_row < matrixA_rows) begin
                        dut__tb__sram_scratchpad_write_enable <= 1'b0;
                        dut__tb__sram_scratchpad_read_address <= weight_col + (weight_row * matrixB_cols) + (matrixB_cols * matrixA_rows);

                        weight_row <= weight_row + 1;
                        state <= ACCUM_RESULT;
                    end
                    else begin
                        weight_row <= 0;
                        state <= ATTENTION_MAT_WRITE_RESULTS;
                    end
                end
            end
            ATTENTION_MAT_WRITE_RESULTS: begin
                // Write result to SRAM
                dut__tb__sram_result_write_enable <= 1'b1;
                dut__tb__sram_result_write_address <= input_row * matrixB_cols + weight_col + (i_matrix * (matrixA_rows * matrixB_cols)) + (matrixA_rows * matrixA_rows);
                dut__tb__sram_result_write_data <= mac_result_z1;
                enable_mac1 <= 64'h0;

                if (weight_col < matrixB_cols) begin
                    if ((weight_col == matrixB_cols-1)) begin
                        weight_col <= (input_row == matrixA_rows - 1) ? (weight_col + 1) : 0;
                        input_row <= input_row + 1;
                    end else begin
                        weight_col <= weight_col + 1;
                    end
                    state <= ATTENTION_MAT_REQ;
                end 
            end
            DONE: begin
                dut_ready <= 1'b1; //Signal that computation is complete
                state <= IDLE;
            end
        endcase
    end
end

assign mac_result_z = enable_mac ? (tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data + accum_result) : 0;

assign mac_result_z1 = enable_mac1 ? (tb__dut__sram_result_read_data * tb__dut__sram_scratchpad_read_data + accum_result1) : 0;

endmodule


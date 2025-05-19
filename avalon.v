module avalon (
    input wire clk,
    input wire resetn,
    output reg valid,
    input wire ready,
    output reg [7:0] data
);

    // Codificação dos estados (Verilog 2001 compatível)
    parameter S_IDLE        = 3'd0;
    parameter S_WAIT_READY  = 3'd1;
    parameter S_VALID_4     = 3'd2;
    parameter S_VALID_5     = 3'd3;
    parameter S_VALID_6     = 3'd4;
    parameter S_HOLD        = 3'd5;
    parameter S_DONE        = 3'd6;

    reg [2:0] state;
    reg [2:0] next_state;

    // Armazena os dados
    reg [7:0] dados[0:2];
    reg [1:0] index;

    // Armazena ready anterior
    reg ready_prev;

    initial begin
        dados[0] = 8'd4;
        dados[1] = 8'd5;
        dados[2] = 8'd6;
    end

    // Lógica sequencial
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= S_IDLE;
            index <= 0;
            valid <= 0;
            data <= 8'd0;
            ready_prev <= 0;
        end else begin
            ready_prev <= ready;
            state <= next_state;
        end
    end

    // Lógica de transição de estado
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (ready)
                    next_state = S_WAIT_READY;
            end

            S_WAIT_READY: begin
                next_state = S_VALID_4;
            end

            S_VALID_4: begin
                if (ready)
                    next_state = S_VALID_5;
                else
                    next_state = S_HOLD;
            end

            S_VALID_5: begin
                if (ready)
                    next_state = S_VALID_6;
                else
                    next_state = S_HOLD;
            end

            S_VALID_6: begin
                if (ready)
                    next_state = S_DONE;
                else
                    next_state = S_HOLD;
            end

            S_HOLD: begin
                if (ready)
                    case (index)
                        1: next_state = S_VALID_5;
                        2: next_state = S_VALID_6;
                        default: next_state = S_DONE;
                    endcase
                else
                    next_state = S_DONE; // só segura por 1 ciclo
            end

            S_DONE: begin
                next_state = S_DONE;
            end
        endcase
    end

    // Saída: Moore (baseada apenas no estado)
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            valid <= 0;
            data <= 8'd0;
            index <= 0;
        end else begin
            case (next_state)
                S_VALID_4: begin
                    valid <= 1;
                    data <= dados[0];
                    index <= 1;
                end
                S_VALID_5: begin
                    valid <= 1;
                    data <= dados[1];
                    index <= 2;
                end
                S_VALID_6: begin
                    valid <= 1;
                    data <= dados[2];
                    index <= 3;
                end
                S_HOLD: begin
                    valid <= 1;
                    data <= dados[index - 1];
                end
                default: begin
                    valid <= 0;
                end
            endcase
        end
    end

endmodule

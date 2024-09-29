/**************************
FILENAME     :  video_uut.sv
PROJECT      :  Hack the Hill 2024
**************************/

/*  INSTANTIATION TEMPLATE  -------------------------------------------------

video_uut video_uut (       
    .clk_i          ( ),//               
    .cen_i          ( ),//
    .vid_sel_i      ( ),//
    .vdat_bars_i    ( ),//[19:0]
    .vdat_colour_i  ( ),//[19:0]
    .fvht_i         ( ),//[ 3:0]
    .fvht_o         ( ),//[ 3:0]
    .video_o        ( ) //[19:0]
);

-------------------------------------------------------------------------- */
module video_uut (
    input  wire         clk_i           ,// clock
    input  wire         cen_i           ,// clock enable
    input  wire         vid_sel_i       ,// select source video
    input  wire [19:0]  vdat_bars_i     ,// input video {luma, chroma}
    input  wire [19:0]  vdat_colour_i   ,// input video {luma, chroma}
    input  wire [3:0]   fvht_i          ,// input video timing signals
	 input  wire [3:0]   user_paddle_speed,
    output wire [3:0]   fvht_o          ,// 1 clk pulse after falling edge on input signal
    output wire [19:0]  video_o          // 1 clk pulse after any edge on input signal
); 

    // Parameters for the game elements
    parameter SCREEN_WIDTH = 1920;
    parameter SCREEN_HEIGHT = 1125;
    parameter PADDLE_WIDTH = 45;
    parameter PADDLE_HEIGHT = 250;
    parameter PADDLE_SPEED = 2;
    parameter PADDLE_START_Y = SCREEN_HEIGHT - PADDLE_HEIGHT - 10; // Start near the bottom
    parameter BALL_SIZE = 30;
    parameter BALL_SPEED_X = 3;
    parameter BALL_SPEED_Y = 1;

    // Define paddle X positions
    parameter LEFT_PADDLE_X = 0;
    parameter RIGHT_PADDLE_X = SCREEN_WIDTH - PADDLE_WIDTH;

    // Counter display position
    parameter COUNTER_X = SCREEN_WIDTH / 2 - 32; // Adjust as needed
    parameter COUNTER_Y = 10; // 10 pixels from the top

    // Center line parameters
    parameter CENTER_LINE_WIDTH = 4;
    parameter CENTER_LINE_SEGMENT = 20;
    parameter CENTER_LINE_GAP = 10;

    reg [19:0]  vid_d1;
    reg [3:0]   fvht_d1;
    reg [10:0]  left_paddle_y = PADDLE_START_Y;
    reg [10:0]  right_paddle_y = PADDLE_START_Y;
    reg         left_paddle_dy = 0;  // 0 for moving up, 1 for moving down
    reg         right_paddle_dy = 0; // 0 for moving up, 1 for moving down
    reg [10:0]  ball_x = SCREEN_WIDTH / 2;
    reg [10:0]  ball_y = SCREEN_HEIGHT / 2;
    reg         ball_dx = 1; // 1 for right, 0 for left
    reg         ball_dy = 1; // 1 for down, 0 for up

    // Score counters
    reg [3:0] left_score = 4'd0;
    reg [3:0] right_score = 4'd0;

    // Ball color parameters (YCbCr422 format)
    reg [19:0] ball_color = 20'hFFFFF; // Start with white
    reg [2:0] color_index = 3'd0;
    reg [19:0] color_palette [0:7];

    // Temporary variables for ball calculations
    reg [10:0] temp_ball_x;
    reg [10:0] temp_ball_y;
    reg        temp_ball_dx;
    reg        temp_ball_dy;

    // Pixel position counters
    reg [11:0] x_counter = 0;
    reg [11:0] y_counter = 0;
    wire [11:0] pixel_x;
    wire [11:0] pixel_y;

    // Edge detection signals
    wire v_in = fvht_i[2];
    reg v_del;
    wire v_pos;
    wire v_neg;
    wire h_in = fvht_i[1];
    reg h_del;
    wire h_pos;
    wire h_neg;

    // Font for digits 0-9
    reg [7:0] digit_font [0:9][0:7];

    // Generate pixel coordinates
    assign pixel_x = x_counter;
    assign pixel_y = y_counter;

    // Edge detection
    always @(posedge clk_i) begin
        if(cen_i) begin
            v_del <= v_in;
            h_del <= h_in;
        end
    end

    assign v_pos = v_in & ~v_del;
    assign v_neg = ~v_in & v_del;

    assign h_pos = h_in & ~h_del;
    assign h_neg = ~h_in & h_del;

    // Initialize the font patterns and color palette
    initial begin
        // Digit 0
        digit_font[0] = '{8'b00111100, 8'b01100110, 8'b01101110, 8'b01110110, 8'b01100110, 8'b01100110, 8'b00111100, 8'b00000000};
        // Digit 1
        digit_font[1] = '{8'b00011000, 8'b00111000, 8'b00011000, 8'b00011000, 8'b00011000, 8'b00011000, 8'b01111110, 8'b00000000};
        // Digit 2
        digit_font[2] = '{8'b00111100, 8'b01100110, 8'b00000110, 8'b00001100, 8'b00110000, 8'b01100000, 8'b01111110, 8'b00000000};
        // Digit 3
        digit_font[3] = '{8'b00111100, 8'b01100110, 8'b00000110, 8'b00011100, 8'b00000110, 8'b01100110, 8'b00111100, 8'b00000000};
        // Digit 4
        digit_font[4] = '{8'b00001100, 8'b00011100, 8'b00111100, 8'b01101100, 8'b01111110, 8'b00001100, 8'b00001100, 8'b00000000};
        // Digit 5
        digit_font[5] = '{8'b01111110, 8'b01100000, 8'b01111100, 8'b00000110, 8'b00000110, 8'b01100110, 8'b00111100, 8'b00000000};
        // Digit 6
        digit_font[6] = '{8'b00111100, 8'b01100110, 8'b01100000, 8'b01111100, 8'b01100110, 8'b01100110, 8'b00111100, 8'b00000000};
        // Digit 7
        digit_font[7] = '{8'b01111110, 8'b01100110, 8'b00000110, 8'b00001100, 8'b00011000, 8'b00011000, 8'b00011000, 8'b00000000};
        // Digit 8
        digit_font[8] = '{8'b00111100, 8'b01100110, 8'b01100110, 8'b00111100, 8'b01100110, 8'b01100110, 8'b00111100, 8'b00000000};
        // Digit 9
        digit_font[9] = '{8'b00111100, 8'b01100110, 8'b01100110, 8'b00111110, 8'b00000110, 8'b01100110, 8'b00111100, 8'b00000000};

        // Color palette (YCbCr422 format)
        color_palette[0] = 20'hFFFFF; // White
        color_palette[1] = 20'h5ACFF; // Red
        color_palette[2] = 20'h54FFF; // Green
        color_palette[3] = 20'hEA4FF; // Blue
        color_palette[4] = 20'h95CFF; // Yellow
        color_palette[5] = 20'hD54FF; // Cyan
        color_palette[6] = 20'hAA4FF; // Magenta
        color_palette[7] = 20'h7A7FF; // Orange
    end

    // Function to determine if current pixel is in a paddle
    function is_in_paddle;
        input [11:0] px, py, paddle_x, paddle_y;
        begin
            is_in_paddle = (px >= paddle_x && px < paddle_x + PADDLE_WIDTH &&
                            py >= paddle_y && py < paddle_y + PADDLE_HEIGHT);
        end
    endfunction

    // Function to determine if current pixel is in the ball
    function is_in_ball;
        input [11:0] px, py;
        begin
            is_in_ball = (px >= ball_x && px < ball_x + BALL_SIZE &&
                          py >= ball_y && py < ball_y + BALL_SIZE);
        end
    endfunction

    // Function to determine if current pixel is in a digit
    function is_in_digit;
        input [11:0] px, py;
        input [11:0] digit_x, digit_y;
        input [3:0] digit_value;
        input integer digit_position;
        integer x_offset, y_offset;
        begin
            is_in_digit = 0;
            x_offset = px - (digit_x + digit_position * 8);
            y_offset = py - digit_y;
            if (x_offset >= 0 && x_offset < 8 && y_offset >= 0 && y_offset < 8) begin
                // Check if the pixel is set in the font pattern
                if (digit_font[digit_value][y_offset][7 - x_offset])
                    is_in_digit = 1;
            end
        end
    endfunction

    // Function to determine if current pixel is in the center line
    function is_in_center_line;
        input [11:0] px, py;
        begin
            is_in_center_line = (px >= (SCREEN_WIDTH / 2 - CENTER_LINE_WIDTH / 2) &&
                                 px < (SCREEN_WIDTH / 2 + CENTER_LINE_WIDTH / 2) &&
                                 ((py % (CENTER_LINE_SEGMENT + CENTER_LINE_GAP)) < CENTER_LINE_SEGMENT));
        end
    endfunction

    always @(posedge clk_i) begin
        if(cen_i) begin
            // Update pixel counters
            if (h_neg) begin
                x_counter <= 0;
                y_counter <= y_counter + 1;
            end else begin
                x_counter <= x_counter + 1;
            end

            if (v_neg) begin
                y_counter <= 0;
            end

            // Move paddles and update game state on positive edge of vertical sync (start of new frame)
            if (v_pos) begin
                // Move left paddle
                if (left_paddle_dy) begin
                    // Moving down
                    if (left_paddle_y + PADDLE_SPEED >= SCREEN_HEIGHT - PADDLE_HEIGHT) begin
                        left_paddle_y <= SCREEN_HEIGHT - PADDLE_HEIGHT;
                        left_paddle_dy <= 0; // Change direction to up
                    end else begin
                        left_paddle_y <= left_paddle_y + PADDLE_SPEED;
                    end
                end else begin
                    // Moving up
                    if (left_paddle_y <= PADDLE_SPEED) begin
                        left_paddle_y <= 0;
                        left_paddle_dy <= 1; // Change direction to down
                    end else begin
                        left_paddle_y <= left_paddle_y - PADDLE_SPEED;
                    end
                end

                // Move right paddle
                if (right_paddle_dy) begin
                    // Moving down
                    if (right_paddle_y + user_paddle_speed >= SCREEN_HEIGHT - PADDLE_HEIGHT) begin
                        right_paddle_y <= SCREEN_HEIGHT - PADDLE_HEIGHT;
                        right_paddle_dy <= 0; // Change direction to up
                    end else begin
                        right_paddle_y <= right_paddle_y + user_paddle_speed;
                    end
                end else begin
                    // Moving up
                    if (right_paddle_y <= user_paddle_speed) begin
                        right_paddle_y <= 0;
                        right_paddle_dy <= 1; // Change direction to down
                    end else begin
                        right_paddle_y <= right_paddle_y - user_paddle_speed;
                    end
                end

                // Ball movement logic using temporary variables
                temp_ball_dx = ball_dx;
                temp_ball_dy = ball_dy;

                // First, move the ball
                if (ball_dx)
                    temp_ball_x = ball_x + BALL_SPEED_X;
                else
                    temp_ball_x = ball_x - BALL_SPEED_X;

                if (ball_dy)
                    temp_ball_y = ball_y + BALL_SPEED_Y;
                else
                    temp_ball_y = ball_y - BALL_SPEED_Y;

                // Ball collision with top and bottom edges
                if (temp_ball_y <= 0) begin
                    temp_ball_dy = 1; // Moving down
                    temp_ball_y = 0;
                end else if (temp_ball_y >= SCREEN_HEIGHT - BALL_SIZE) begin
                    temp_ball_dy = 0; // Moving up
                    temp_ball_y = SCREEN_HEIGHT - BALL_SIZE;
                end

                // Ball collision with paddles
                if ((temp_ball_x <= PADDLE_WIDTH && temp_ball_y + BALL_SIZE >= left_paddle_y && temp_ball_y <= left_paddle_y + PADDLE_HEIGHT) ||
                    (temp_ball_x >= SCREEN_WIDTH - PADDLE_WIDTH - BALL_SIZE && temp_ball_y + BALL_SIZE >= right_paddle_y && temp_ball_y <= right_paddle_y + PADDLE_HEIGHT)) begin
                    temp_ball_dx = ~temp_ball_dx; // Reverse horizontal direction
                    // Adjust temp_ball_x to prevent ball from sticking to paddle
                    if (temp_ball_x <= PADDLE_WIDTH)
                        temp_ball_x = PADDLE_WIDTH;
                    else
                        temp_ball_x = SCREEN_WIDTH - PADDLE_WIDTH - BALL_SIZE;
                end

                // Ball collision with vertical edges (left and right borders)
                else if (temp_ball_x <= 0) begin
                    temp_ball_dx = 1; // Moving right
                    temp_ball_x = SCREEN_WIDTH / 2;
                    temp_ball_y = SCREEN_HEIGHT / 2;
                    if (right_score < 4'd9) right_score <= right_score + 1;
                    color_index <= color_index + 1;
                    ball_color <= color_palette[color_index];
                end else if (temp_ball_x >= SCREEN_WIDTH - BALL_SIZE) begin
                    temp_ball_dx = 0; // Moving left
                    temp_ball_x = SCREEN_WIDTH / 2;
                    temp_ball_y = SCREEN_HEIGHT / 2;
						  if (left_score < 4'd9) left_score <= left_score + 1;
                    color_index <= color_index + 1;
                    ball_color <= color_palette[color_index];
                end

                // Finally, update the ball's position and direction
                ball_x <= temp_ball_x;
                ball_y <= temp_ball_y;
                ball_dx <= temp_ball_dx;
                ball_dy <= temp_ball_dy;
            end

            // Draw game elements
            vid_d1 <= 20'h0FF00; // Green background

            // Draw center line
            if (is_in_center_line(pixel_x, pixel_y))
                vid_d1 <= 20'hFFFFF; // White center line

            // Draw paddles and ball
            if (is_in_paddle(pixel_x, pixel_y, LEFT_PADDLE_X, left_paddle_y))
                vid_d1 <= 20'hFFFFF; // Left paddle
            else if (is_in_paddle(pixel_x, pixel_y, RIGHT_PADDLE_X, right_paddle_y))
                vid_d1 <= 20'hFFFFF; // Right paddle
            else if (is_in_ball(pixel_x, pixel_y))
                vid_d1 <= ball_color; // Ball with current color

            // Draw the score
            else if (is_in_digit(pixel_x, pixel_y, COUNTER_X, COUNTER_Y, left_score, 0))
                vid_d1 <= 20'hFFFFFF; // Left score
            else if (is_in_digit(pixel_x, pixel_y, COUNTER_X + 16, COUNTER_Y, right_score, 0))
                vid_d1 <= 20'hFFFFFF; // Right score

            // Update timing signals
            fvht_d1 <= fvht_i;
        end
    end

    // OUTPUT
    assign fvht_o  = fvht_d1;
    assign video_o = vid_d1;

endmodule

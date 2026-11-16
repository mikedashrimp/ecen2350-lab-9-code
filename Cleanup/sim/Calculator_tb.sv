`timescale 1ns / 1ps
// Whole-calculator testbench: fakes a keypad by connecting the pressed key's row to its column.
module Calculator_tb;
    logic clk = 0, reset = 0;
    logic [3:0] column, row, AN;
    logic [7:0] SEG;

    Calculator_top dut (.clk(clk), .reset(reset), .column(column), .row(row), .AN(AN), .SEG(SEG));
    always #5 clk = ~clk;

    // pressed key position, physical row/col 1..4 (0 = nothing pressed)
    int pr = 0, pc = 0;
    always_comb column = (pr != 0 && row[4-pr]) ? (4'b0001 << (4-pc)) : 4'b0000;

    int errors = 0;

    task automatic press_pos(input string k, output int r, output int c);
        case (k)
            "1": begin pr=1; pc=1; end  "2": begin pr=1; pc=2; end  "3": begin pr=1; pc=3; end  "+": begin pr=1; pc=4; end
            "4": begin pr=2; pc=1; end  "5": begin pr=2; pc=2; end  "6": begin pr=2; pc=3; end  "-": begin pr=2; pc=4; end
            "7": begin pr=3; pc=1; end  "8": begin pr=3; pc=2; end  "9": begin pr=3; pc=3; end  "x": begin pr=3; pc=4; end
            "C": begin pr=4; pc=1; end  "0": begin pr=4; pc=2; end  "=": begin pr=4; pc=3; end  "/": begin pr=4; pc=4; end
        endcase
        r = pr; c = pc; pr = 0; pc = 0;
    endtask

    task automatic press(input string k);
        int r, c;
        press_pos(k, r, c);
        pr = r; pc = c;
        repeat (300_000) @(posedge clk);  // hold ~3 ms (longer than one full row scan)
        pr = 0; pc = 0;
        repeat (2_100_000) @(posedge clk); // let go for ~21 ms (release debounce is 20 ms)
    endtask

    // Same as press, but the contact chatters on and off for ~3 ms when pressed AND when released
    task automatic press_bouncy(input string k);
        int r, c;
        press_pos(k, r, c);
        for (int i = 0; i < 15; i++) begin
            pr = (i % 2 == 0) ? r : 0; pc = c;
            repeat (20_000 + 7_000*i) @(posedge clk);
        end
        pr = r; pc = c;
        repeat (300_000) @(posedge clk);
        for (int i = 0; i < 15; i++) begin
            pr = (i % 2 == 0) ? 0 : r; pc = c;
            repeat (20_000 + 7_000*i) @(posedge clk);
        end
        pr = 0; pc = 0;
        repeat (2_100_000) @(posedge clk);
    endtask

    task automatic type_str(input string s);
        for (int i = 0; i < s.len(); i++) press(s.substr(i,i));
    endtask

    task automatic check(input string what, input int expected);
        if ($signed(dut.display_num) !== expected) begin
            $display("FAIL  %-28s display=%0d expected=%0d", what, $signed(dut.display_num), expected);
            errors++;
        end else
            $display("ok    %-28s display=%0d", what, $signed(dut.display_num));
    endtask

    initial begin
        repeat (10) @(posedge clk);
        check("power-up", 0);
        type_str("12");   check("typing A = 12", 12);
        press("+");       check("after + shows B (0)", 0);
        type_str("7");    check("typing B = 7", 7);
        press("=");       check("12 + 7", 19);
        press("5");       check("digit ignored on result", 19);
        press("C");       check("clear", 0);
        type_str("9-25=");check("9 - 25", -16);
        press("C");
        type_str("8x4="); check("8 * 4", 32);
        press("C");
        type_str("15/4=");check("15 / 4", 3);
        press("C");
        type_str("6/0="); check("6 / 0 (guarded)", 0);
        press("C");
        type_str("=");    check("= with no operator ignored", 0);
        type_str("30+");
        reset = 1; repeat (5) @(posedge clk); reset = 0; repeat (5) @(posedge clk);
        check("reset button clears", 0);
        type_str("3+4="); check("works after reset", 7);
        press("C");
        press_bouncy("4"); check("bouncy 4 counts once", 4);
        press_bouncy("4"); check("bouncy 4 again -> 44", 44);
        press("C");
        if (errors == 0) $display("ALL PASSED"); else $display("%0d FAILURE(S)", errors);
        $finish;
    end
endmodule

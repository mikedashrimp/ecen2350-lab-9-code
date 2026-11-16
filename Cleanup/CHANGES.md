# What was changed (and why)

The design is still yours: same modules, same port names, same keypad codes, and the same split of jobs
between blocks. Every edit in the code has a `// FIX:` comment next to it, so you can search for "FIX".

## Which files to use
Use these files, all with proper extensions: Vivado needs `.sv` to read a file as SystemVerilog,
and the originals had no extension.

| File | Came from |
|---|---|
| `Control_block.sv` | `Control_block` (holds `Calculator_top` **and** `Control_block`) |
| `Keypad.sv` | `Keypad code` |
| `memory_block.sv` | `mem try 4` |
| `ALU_block.sv` | `ALU block code` |
| `Display_block.sv` | `Display block code try 2` |
| `Calculator_pins.xdc` | `Display constraints file` |
| `ALU_tb.sv`, `mem_tb.sv` | your testbenches (simulation sources only) |

Leave out the older attempts (`Display block code`, `memory attempt 2`, `mem try 3`, the README memory
module, the empty `Control block 2`). They have syntax errors and would break the build if added.
**Set `Calculator_top` as the top module.**

## Things that stopped it from building
1. **ALU**: case labels were `0'b00`, but a 0-bit width isn't legal, so they are now `2'b00`. There was also an extra `end endmodule` at the bottom.
2. **Top level**: it instantiated `CalculatorControl`, but the module is called `Control_block`. Two port names were also misspelled (`.out_typ`, `.ALU_resul`).
3. **Memory**: `out` was set in both the `always_ff` (on clear) and the `always_comb`. Only one block can drive a signal, so I removed the one in the `always_ff`. Clear still shows 0 because `out` follows `a`.
4. **Display**: an unpacked array literal needs `'{ ... }` (with the apostrophe), not `{ ... }`.
5. **Constraints**: the keypad `row`/`column` pins were missing. I added them (with pull-downs on the columns). The bit order is flipped to match your Keypad, where row 1 = bit 3. The `number[...]` switch pins from testing the display on its own are commented out, because `number` is now an internal wire.

## Round 2: Keypad / Control split (marked `// REWRITE:`)
Key-press handling used to live in `Control_block`, which read the raw column pins. It is now split up like this:

- **Keypad** handles all of the input. It scans R1-R4 and checks the columns at the *end* of each row's
  time, after the pins have settled. When it finds a key, it saves `key_data` and `data_type`
  (0 number, 1 operator, 2 equals, 3 clear) and pulses `new_input` for one clock. It then keeps driving
  that row until the key has been released for 20 ms (debounce), so one press = one `new_input`.
  It uses the same key codes and row/column order as before. `data_type` and `new_input` were already
  ports you had planned; they're now actually used.
- **Control_block** is only the calculator's state machine (`in_a` -> `in_b` -> `result`), written as a
  state register, next-state logic and output logic. It never touches the column pins. On each
  `new_input` it decides whether to write A, B or op, or to clear, and `out_type` follows the state.
- **Calculator_top** wires `data_type` and `new_input` from Keypad to Control. Nothing else changed.

Behavior worth knowing:
- After you press an operator, the display switches to B, which starts at 0 (like a normal calculator).
- Once a result is showing, only Clear does anything. Equals is ignored until an operator has been entered.
- Clear works from any state. The reset button also clears A, B and op.
- Divide by zero shows 0.

## Tested
`sim/Calculator_tb.sv` is a full-calculator simulation with a fake keypad, and all 16 checks pass:
12+7=19, 9-25=-16, 8*4=32, 15/4=3, 6/0=0, clear, the reset button, digits ignored after a result, and a
button that chatters on press and release still counting as exactly one press.
(It simulates ~0.4 s of real time, so it takes a while to run in Vivado's simulator.)

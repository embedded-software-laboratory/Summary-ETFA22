FUNCTION_BLOCK F_TRIG
VAR_INPUT
   CLK: BOOL;
END_VAR
VAR_OUTPUT
   Q: BOOL;
END_VAR
VAR
   M: BOOL;
END_VAR
Q := NOT CLK AND M;
M := CLK;
END_FUNCTION_BLOCK
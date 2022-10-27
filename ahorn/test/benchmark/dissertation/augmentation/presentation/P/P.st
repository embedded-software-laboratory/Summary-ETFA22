PROGRAM P
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR
    y := x;
    IF y > 1 THEN
        z := TRUE;
    ELSE
        z := FALSE;
    END_IF;
END_PROGRAM
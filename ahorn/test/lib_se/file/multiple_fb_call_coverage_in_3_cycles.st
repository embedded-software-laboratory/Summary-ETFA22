PROGRAM P
VAR_INPUT
    a : INT;
END_VAR
VAR
    f : Fb1;
    g : Fb2;
    h : Fb3;
    i : Fb4;
    j : Fb5;
    k : Fb6;
    l : Fb7;
    m : Fb8;
    n : Fb9;
    o : Fb10;
END_VAR
VAR_OUTPUT
    b : BOOL;
END_VAR
    f(x:=a,z=>b);
    g(x:=a,z=>b);
    h(x:=a,z=>b);
    i(x:=a,z=>b);
    j(x:=a,z=>b);
    k(x:=a,z=>b);
    l(x:=a,z=>b);
    m(x:=a,z=>b);
    n(x:=a,z=>b);
    o(x:=a,z=>b);
END_PROGRAM

FUNCTION_BLOCK Fb1
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb2
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb3
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb4
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb5
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb6
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb7
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb8
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb9
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Fb10
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
    IF x >= 32 THEN
        y := y + 1;
    ELSE
        y := y;
    END_IF;
    IF y >= 3 THEN
        z := TRUE;
        y := 0;
    ELSE
        z := FALSE;
    END_IF;
END_FUNCTION_BLOCK

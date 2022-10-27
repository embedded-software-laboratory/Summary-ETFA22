PROGRAM P
VAR_INPUT
    a : INT;
END_VAR
VAR
    f : Fb;
END_VAR
VAR_OUTPUT
    b : BOOL;
END_VAR
    f(x:=a,z=>b);
END_PROGRAM

FUNCTION_BLOCK Fb
VAR_INPUT
    x : INT;
END_VAR
VAR
    y : INT;
END_VAR
VAR_OUTPUT
    z : BOOL;
END_VAR;
CASE x OF
1:
    IF y = 0 THEN
        y := y + 1;
    END_IF;
2:
    IF y = 1 THEN
        y := y + 1;
    END_IF;
3:
    IF y = 3 THEN
        y := y + 1;
    END_IF;
4:
    y := 4;
5:
    y := 5;
6:
    y := 6;
7:
    y := 7;
8:
    y := 8;
9:
    y := 9;
10:
    y := 10;
11:
    y := 11;
12:
    y := 12;
13:
    y := 13;
14:
    y := 14;
15:
    y := 15;
16:
    y := 16;
17:
    y := 17;
18:
    y := 18;
19:
    y := 19;
20:
    y := 20;
END_CASE;
END_FUNCTION_BLOCK
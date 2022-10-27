FUNCTION_BLOCK SF_TwoHandControlTypeIII2
 VAR_INPUT
    Activate          : BOOL;
    S_Button1         : SAFEBOOL;
    S_Button2         : SAFEBOOL;
 END_VAR

 VAR_OUTPUT
    Ready             : BOOL;
    S_TwoHandOut      : SAFEBOOL;
    Error             : BOOL;
    DiagCode          : WORD:=16#0000;
 END_VAR

 VAR
    T_1: TONX;
 END_VAR

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE

CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
16#8000:
    IF S_Button1 AND NOT S_Button2 THEN
        DiagCode := 16#8007;
    ELSIF NOT S_Button1 AND S_Button2 THEN
        DiagCode := 16#8008;
    ELSIF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    END_IF;
16#8001:
    IF S_Button1 AND S_Button2 THEN
        DiagCode := 16#C003;
    ELSIF S_Button1 THEN
        DiagCode := 16#C001;
    ELSIF S_Button2 THEN
        DiagCode := 16#C002;
    ELSIF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    END_IF;
16#8004:
    IF S_Button1 AND S_Button2 THEN
        DiagCode := 16#8000;
    ELSIF S_Button1 THEN
        DiagCode := 16#8005;
    ELSIF S_Button2 THEN
        DiagCode := 16#8006;
    END_IF;
16#8005:
    IF T_1.Q THEN
        IF S_Button1 AND S_Button2 THEN
            DiagCode := 16#C006;
        ELSIF S_Button1 THEN
            DiagCode := 16#C005;
        ELSIF S_Button2 THEN
            DiagCode := 16#C004;
        END_IF;
    ELSIF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    ELSIF NOT S_Button1 AND S_Button2 THEN
        DiagCode := 16#8019;
    ELSIF S_Button1 AND S_Button2 THEN
        DiagCode := 16#8000;
    END_IF;
16#8006:
    IF T_1.Q THEN
        IF S_Button1 AND S_Button2 THEN
            DiagCode := 16#C006;
        ELSIF S_Button1 THEN
            DiagCode := 16#C005;
        ELSIF S_Button2 THEN
            DiagCode := 16#C004;
        END_IF;
    ELSIF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    ELSIF S_Button1 AND NOT S_Button2 THEN
        DiagCode := 16#8019;
    ELSIF S_Button1 AND S_Button2 THEN
        DiagCode := 16#8000;
    END_IF;
16#8007:
    IF S_Button1 AND S_Button2 THEN
        DiagCode := 16#8009;
    ELSIF NOT S_Button1 AND S_Button2 THEN
        DiagCode := 16#8008;
    ELSIF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    END_IF;
16#8008:
    IF S_Button1 AND S_Button2 THEN
        DiagCode := 16#8009;
    ELSIF S_Button1 AND NOT S_Button2 THEN
        DiagCode := 16#8007;
    ELSIF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    END_IF;
16#8009:
    IF NOT S_Button1 AND S_Button2 THEN
        DiagCode := 16#8008;
    ELSIF S_Button1 AND NOT S_Button2 THEN
        DiagCode := 16#8007;
    ELSIF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    END_IF;
16#8019:
    IF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    END_IF;
16#C001,
16#C002,
16#C003,
16#C004,
16#C005,
16#C006:
    IF NOT (S_Button1 OR S_Button2) THEN
        DiagCode := 16#8004;
    END_IF;
END_CASE;
END_IF;

IF DiagCode = 16#8005 OR DiagCode = 16#8006 THEN
T_1(IN:=1, PT:=TIME#500ms);
ELSE
T_1(IN:=0, PT:=TIME#500ms);
END_IF;

CASE DiagCode OF
16#0000:
    Ready := FALSE;
    S_TwoHandOut := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    S_TwoHandOut := TRUE;
    Error := FALSE;
16#8001,
16#8004,
16#8005,
16#8006,
16#8007,
16#8008,
16#8009,
16#8019:
    Ready := TRUE;
    S_TwoHandOut := FALSE;
    Error := FALSE;
16#C001,
16#C002,
16#C003,
16#C004,
16#C005,
16#C006:
    Ready := TRUE;
    S_TwoHandOut := FALSE;
    Error := TRUE;
END_CASE;

END_FUNCTION_BLOCK

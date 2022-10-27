PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SButton1 : SAFEBOOL;
    SButton2 : SAFEBOOL;
END_VAR
VAR
    SFTwoHandControlTypeIII : SFTwoHandControlTypeIII;
END_VAR
SFTwoHandControlTypeIII(Activate:=Activate,SButton1:=SButton1,SButton2:=SButton2);
END_PROGRAM

FUNCTION_BLOCK SFTwoHandControlTypeIII
VAR_INPUT
    Activate : BOOL;
    SButton1 : SAFEBOOL;
    SButton2 : SAFEBOOL;
END_VAR
VAR
    IN : BOOL;
    PT : TIME;
    running : BOOL;
    Q : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL;
    STwoHandOut : SAFEBOOL;
    Error : BOOL;
    DiagCode : WORD:=16#0000;
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
        IF SButton1 AND NOT SButton2 THEN
            DiagCode := 16#8007;
        ELSIF NOT SButton1 AND SButton2 THEN
            DiagCode := 16#8008;
        ELSIF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        END_IF;
    16#8001:
        IF SButton1 AND SButton2 THEN
            DiagCode := 16#C003;
        ELSIF SButton1 THEN
            DiagCode := 16#C001;
        ELSIF SButton2 THEN
            DiagCode := 16#C002;
        ELSIF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        END_IF;
    16#8004:
        IF SButton1 AND SButton2 THEN
            DiagCode := 16#8000;
        ELSIF SButton1 THEN
            DiagCode := change(16#8005, 16#8000);
        ELSIF SButton2 THEN
            DiagCode := 16#8006;
        END_IF;
    16#8005:
        IF Q THEN
            IF SButton1 AND SButton2 THEN
                DiagCode := 16#C006;
            ELSIF SButton1 THEN
                DiagCode := 16#C005;
            ELSIF SButton2 THEN
                DiagCode := 16#C004;
            END_IF;
        ELSIF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        ELSIF NOT SButton1 AND SButton2 THEN
            DiagCode := 16#8019;
        ELSIF SButton1 AND SButton2 THEN
            DiagCode := 16#8000;
        END_IF;
    16#8006:
        IF Q THEN
            IF SButton1 AND SButton2 THEN
                DiagCode := 16#C006;
            ELSIF SButton1 THEN
                DiagCode := 16#C005;
            ELSIF SButton2 THEN
                DiagCode := 16#C004;
            END_IF;
        ELSIF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        ELSIF SButton1 AND NOT SButton2 THEN
            DiagCode := 16#8019;
        ELSIF SButton1 AND SButton2 THEN
            DiagCode := 16#8000;
        END_IF;
    16#8007:
        IF SButton1 AND SButton2 THEN
            DiagCode := 16#8009;
        ELSIF NOT SButton1 AND SButton2 THEN
            DiagCode := 16#8008;
        ELSIF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        END_IF;
    16#8008:
        IF SButton1 AND SButton2 THEN
            DiagCode := 16#8009;
        ELSIF SButton1 AND NOT SButton2 THEN
            DiagCode := 16#8007;
        ELSIF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        END_IF;
    16#8009:
        IF NOT SButton1 AND SButton2 THEN
            DiagCode := 16#8008;
        ELSIF SButton1 AND NOT SButton2 THEN
            DiagCode := 16#8007;
        ELSIF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        END_IF;
    16#8019:
        IF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        END_IF;
    16#C001,
    16#C002,
    16#C003,
    16#C004,
    16#C005,
    16#C006:
        IF NOT (SButton1 OR SButton2) THEN
            DiagCode := 16#8004;
        END_IF;
    END_CASE;
END_IF;
IF DiagCode = 16#8005 OR DiagCode = 16#8006 THEN
    IN:=TRUE;
    PT:=TIME#500ms;
    IF NOT running AND NOT Q THEN
        running := TRUE;
    ELSIF running AND NOT Q THEN
        Q := NONDETERMINISTIC_BOOL();
        running := NOT Q;
    END_IF;
ELSE
    IN:=FALSE;
    PT:=TIME#500ms;
    Q := FALSE;
    running := FALSE;
END_IF;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    STwoHandOut := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    STwoHandOut := TRUE;
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
    STwoHandOut := FALSE;
    Error := FALSE;
16#C001,
16#C002,
16#C003,
16#C004,
16#C005,
16#C006:
    Ready := TRUE;
    STwoHandOut := FALSE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK
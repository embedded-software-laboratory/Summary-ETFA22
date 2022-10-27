PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SChannelNC : SAFEBOOL;
    SChannelNO : SAFEBOOL;
    DiscrepancyTime : TIME;
END_VAR
VAR
    SFAntivalent : SFAntivalent;
END_VAR
SFAntivalent(Activate:=Activate,SChannelNC:=SChannelNC,SChannelNO:=SChannelNO,DiscrepancyTime:=DiscrepancyTime);
END_PROGRAM

FUNCTION_BLOCK SFAntivalent
VAR_INPUT
    Activate : BOOL;
    SChannelNC : SAFEBOOL;
    SChannelNO : SAFEBOOL;
    DiscrepancyTime : TIME;
END_VAR
VAR
    IN : BOOL;
    PT : TIME;
    running : BOOL;
    Q : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL;
    SAntivalentOut : BOOL;
    Error : BOOL;
    DiagCode : WORD;
END_VAR

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
    16#0000:
        IF Activate THEN
            DiagCode := 16#8001;
        END_IF;
    16#8001:
        IF SChannelNC AND SChannelNO THEN
            DiagCode := 16#8004;
            IN:=TRUE;
            PT:=DiscrepancyTime;
            IF NOT running AND NOT Q THEN
                running := TRUE;
            ELSIF running AND NOT Q THEN
                Q := NONDETERMINISTIC_BOOL();
                running := NOT Q;
            END_IF;
        ELSIF NOT SChannelNC AND NOT SChannelNO THEN
            DiagCode := 16#8014;
            IN:=TRUE;
            PT:=DiscrepancyTime;
            IF NOT running AND NOT Q THEN
                running := TRUE;
            ELSIF running AND NOT Q THEN
                Q := NONDETERMINISTIC_BOOL();
                running := NOT Q;
            END_IF;
        ELSIF SChannelNC AND NOT SChannelNO THEN
            DiagCode := 16#8000;
        END_IF;
    16#8004:
        IF Q THEN
            DiagCode := 16#C001;
        ELSIF NOT SChannelNC THEN
            DiagCode := 16#8001;
        ELSIF NOT SChannelNO THEN
            DiagCode := 16#8000;
        END_IF;
    16#C001,
    16#C002:
        IF NOT SChannelNC AND SChannelNO THEN
            DiagCode := 16#8001;
        END_IF;
    16#8014:
        IF Q THEN
            DiagCode := 16#C002;
        ELSIF SChannelNO THEN
            DiagCode := 16#8001;
        ELSIF SChannelNC THEN
            DiagCode := 16#8000;
        END_IF;
    16#C003:
        IF NOT SChannelNC AND SChannelNO THEN
            DiagCode := 16#8001;
        END_IF;
    16#8005:
        IF Q THEN
            DiagCode := 16#C003;
        ELSIF NOT SChannelNC AND SChannelNO THEN
            DiagCode := 16#8001;
        END_IF;
    16#8000:
        IF NOT SChannelNC OR SChannelNO THEN
            DiagCode := 16#8005;
            IN:=TRUE;
            PT:=DiscrepancyTime;
            IF NOT running AND NOT Q THEN
                running := TRUE;
            ELSIF running AND NOT Q THEN
                Q := NONDETERMINISTIC_BOOL();
                running := NOT Q;
            END_IF;
        ELSIF NOT SChannelNC AND SChannelNO THEN
            DiagCode := 16#8001;
        END_IF;
    END_CASE;
END_IF;
    
CASE DiagCode OF
16#0000:
    Q := FALSE;
    running := FALSE;
    Ready := FALSE;
    Error := FALSE;
    SAntivalentOut:= FALSE;
16#8000:
    Q := FALSE;
    running := FALSE;
    Ready := TRUE;
    Error := FALSE;
    SAntivalentOut := TRUE;
16#8001:
    IN:=FALSE;
    PT:=DiscrepancyTime;
    Q := FALSE;
    running := FALSE;
    Ready := TRUE;
    Error := FALSE;
    SAntivalentOut:= FALSE;
16#8004,
16#8014,
16#8005:
    IN := TRUE;
    PT := DiscrepancyTime;
    IF NOT running AND NOT Q THEN
        running := TRUE;
    ELSIF running AND NOT Q THEN
        Q := NONDETERMINISTIC_BOOL();
        running := NOT Q;
    END_IF;
    Ready := TRUE;
    Error := FALSE;
    SAntivalentOut:= FALSE;
16#C001,
16#C002,
16#C003:
    IN := FALSE;
    PT := DiscrepancyTime;
    Q := FALSE;
    running := FALSE;
    Ready := TRUE;
    Error := TRUE;
    SAntivalentOut:= FALSE;
END_CASE;
END_FUNCTION_BLOCK
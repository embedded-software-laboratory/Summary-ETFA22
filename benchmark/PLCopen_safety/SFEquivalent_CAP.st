PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SChannelA : BOOL;
    SChannelB : BOOL;
    DiscrepancyTime : TIME;
END_VAR
VAR
    SFEquivalent : SFEquivalent;
END_VAR
SFEquivalent(Activate:=Activate,SChannelA:=SChannelA,SChannelB:=SChannelB,DiscrepancyTime:=DiscrepancyTime);
END_PROGRAM

FUNCTION_BLOCK SFEquivalent
VAR_INPUT
    Activate : BOOL;
    SChannelA : BOOL;
    SChannelB : BOOL;
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
	SEquivalentOut : BOOL;
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
        IF SChannelA AND NOT SChannelB THEN
            DiagCode := 16#8004;
        ELSIF SChannelB AND NOT SChannelA THEN
            DiagCode := 16#8014;
        ELSIF SChannelA AND SChannelB THEN
            DiagCode := 16#8000;
        END_IF;
    16#8004:
        IF Q THEN
            DiagCode := 16#C001;
        ELSIF NOT SChannelA THEN
            DiagCode := 16#8001;
        ELSIF SChannelB THEN
            DiagCode := change(16#8000, 16#8004);
        END_IF;
    16#C001,
    16#C002:
        IF NOT SChannelA AND NOT SChannelB THEN
            DiagCode := 16#8001;
        END_IF;
    16#8014:
        IF Q THEN
            DiagCode := 16#C002;
        ELSIF NOT SChannelB THEN
            DiagCode := 16#8001;
        ELSIF SChannelA THEN
            DiagCode := 16#8000;
        END_IF;
    16#C003:
        IF NOT SChannelA AND NOT SChannelB THEN
            DiagCode := 16#8001;
        END_IF;
    16#8005:
        IF Q THEN
            DiagCode := 16#C003;
        ELSIF NOT SChannelA AND NOT SChannelB THEN
            DiagCode := 16#8001;
        END_IF;
    16#8000:
        IF SChannelA XOR SChannelB THEN
            DiagCode := 16#8005;
        ELSIF NOT SChannelA AND NOT SChannelB THEN
            DiagCode := 16#8001;
        END_IF;
    END_CASE;
END_IF;

CASE DiagCode OF
16#0000:
    IN:=FALSE;
    PT:=DiscrepancyTime;
    Q := FALSE;
    running := FALSE;
    Ready := FALSE;
    Error := FALSE;
    SEquivalentOut:= FALSE;
16#8000:
    IN:=FALSE;
    PT:=DiscrepancyTime;
    Q := FALSE;
    running := FALSE;
    Ready := TRUE;
    Error := FALSE;
    SEquivalentOut := TRUE;
16#8001:
    IN:=FALSE;
    PT:=DiscrepancyTime;
    Q := FALSE;
    running := FALSE;
    Ready := TRUE;
    Error := FALSE;
    SEquivalentOut:= FALSE;
16#8004,
16#8014,
16#8005:
	IN:=TRUE;
	PT:=DiscrepancyTime;
	IF NOT running AND NOT Q THEN
        running := TRUE;
    ELSIF running AND NOT Q THEN
        Q := NONDETERMINISTIC_BOOL();
        running := NOT Q;
    END_IF;
    Ready := TRUE;
    Error := FALSE;
    SEquivalentOut:= FALSE;
16#C001,
16#C002,
16#C003:
    IN:=FALSE;
    PT:=DiscrepancyTime;
    Q := FALSE;
    running := FALSE;
    Ready := TRUE;
    Error := TRUE;
    SEquivalentOut:= FALSE;
END_CASE;
END_FUNCTION_BLOCK
FUNCTION_BLOCK SF_Antivalent
 VAR_INPUT
        Activate           : BOOL;
        S_ChannelNC        : SAFEBOOL;
        S_ChannelNO        : SAFEBOOL;
        DiscrepancyTime    : TIME;
 END_VAR
 VAR_OUTPUT
        Ready              : BOOL;
        S_AntivalentOut    : BOOL;
        Error              : BOOL;
        DiagCode           : WORD;
 END_VAR
 VAR
        T_1        : TON;
 END_VAR

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE

CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := change(16#8001,16#8002);
    END_IF;
16#8001:
    IF S_ChannelNC AND S_ChannelNO THEN
        DiagCode := 16#8004;
        T_1(IN:=TRUE, PT:=DiscrepancyTime);
    ELSIF NOT S_ChannelNC AND NOT S_ChannelNO THEN
        DiagCode := 16#8014;
        T_1(IN:=TRUE, PT:=DiscrepancyTime);
    ELSIF S_ChannelNC AND NOT S_ChannelNO THEN
        DiagCode := 16#8000;
    END_IF;
16#8004:
    IF T_1.Q THEN
        DiagCode := 16#C001;
    ELSIF NOT S_ChannelNC THEN
        DiagCode := 16#8001;
    ELSIF NOT S_ChannelNO THEN
        DiagCode := 16#8000;
    END_IF;
16#C001,
16#C002:
    IF NOT S_ChannelNC AND S_ChannelNO THEN
        DiagCode := 16#8001;
    END_IF;
16#8014:
    IF T_1.Q THEN
        DiagCode := 16#C002;
    ELSIF S_ChannelNO THEN
        DiagCode := 16#8001;
    ELSIF S_ChannelNC THEN
        DiagCode := 16#8000;
    END_IF;
16#C003:
    IF NOT S_ChannelNC AND S_ChannelNO THEN
        DiagCode := 16#8001;
    END_IF;
16#8005:
    IF T_1.Q THEN
        DiagCode := 16#C003;
    ELSIF NOT S_ChannelNC AND S_ChannelNO THEN
        DiagCode := 16#8001;
    END_IF;
16#8000:
    IF NOT S_ChannelNC OR S_ChannelNO THEN
        DiagCode := 16#8005;
        T_1(IN:=TRUE, PT:=DiscrepancyTime);
    ELSIF NOT S_ChannelNC AND S_ChannelNO THEN
        DiagCode := 16#8001;
    END_IF;
END_CASE;
END_IF;

CASE DiagCode OF
16#0000:
    T_1(IN:=FALSE, PT:=DiscrepancyTime);
    Ready := FALSE;
    Error := FALSE;
    S_AntivalentOut:= FALSE;
16#8000:
    T_1(IN:=FALSE, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := FALSE;
    S_AntivalentOut := TRUE;
16#8001:
    T_1(IN:=FALSE, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := FALSE;
    S_AntivalentOut:= FALSE;
16#8004,
16#8014,
16#8005:
    Ready := TRUE;
    Error := FALSE;
    S_AntivalentOut:= FALSE;
16#C001,
16#C002,
16#C003:
    T_1(IN:=FALSE, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := TRUE;
    S_AntivalentOut:= FALSE;
END_CASE;

END_FUNCTION_BLOCK
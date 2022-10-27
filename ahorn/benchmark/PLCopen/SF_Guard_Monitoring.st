FUNCTION_BLOCK SF_Guard_Monitoring
VAR_INPUT
        Activate        : BOOL := FALSE;
        S_GuardSwitch1  : SAFEBOOL := FALSE;
        S_GuardSwitch2  : SAFEBOOL := FALSE;
        DiscrepancyTime : TIME := T#0s;
        S_StartReset    : SAFEBOOL := FALSE;
        S_AutoReset     : SAFEBOOL := FALSE;
        Reset           : BOOL := FALSE;
END_VAR
VAR_OUTPUT
        Ready             : BOOL := FALSE;
        S_GuardMonitoring : BOOL := FALSE;
        Error             : BOOL := FALSE;
        DiagCode          : WORD := 16#0000;
END_VAR
VAR
    R_TRIGatReset : R_TRIG;
    DiscrepancyTimer : TON;
END_VAR

R_TRIGatReset(CLK:=Reset);

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE

CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
16#8001:
    IF NOT S_GuardSwitch1 OR NOT S_GuardSwitch2 THEN
        DiagCode := 16#8002;
    ELSIF S_GuardSwitch1 AND S_GuardSwitch2 AND NOT S_StartReset THEN
        DiagCode := 16#8003;
    ELSIF S_GuardSwitch1 AND S_GuardSwitch2 AND S_StartReset THEN
        DiagCode := 16#8000;
    END_IF;
16#8002:
    IF NOT S_GuardSwitch1 AND NOT S_GuardSwitch2 THEN
        DiagCode := 16#8012;
    END_IF;
16#8003:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C001;
    ELSIF NOT S_GuardSwitch1 OR NOT S_GuardSwitch2 THEN
        DiagCode := 16#8002;
    ELSIF R_TRIGatReset.Q THEN
        DiagCode := 16#8000;
    END_IF;
16#8012:
    IF S_GuardSwitch1 THEN
        DiagCode := 16#8004;
        DiscrepancyTimer(IN:=TRUE, PT:=DiscrepancyTime);
    ELSIF S_GuardSwitch2 THEN
        DiagCode := 16#8014;
        DiscrepancyTimer(IN:=TRUE, PT:=DiscrepancyTime);
    END_IF;
16#8004:
    IF DiscrepancyTimer.Q THEN
        DiagCode := 16#C011;
    ELSIF NOT S_GuardSwitch1 THEN
        DiagCode := 16#8002;
    ELSIF S_GuardSwitch2 THEN
        DiagCode := 16#8005;
    END_IF;
16#8014:
    IF DiscrepancyTimer.Q THEN
        DiagCode := 16#C012;
    ELSIF NOT S_GuardSwitch2 THEN
        DiagCode := 16#8002;
    ELSIF S_GuardSwitch1 THEN
        DiagCode := 16#8005;
    END_IF;
16#8005:
    IF NOT S_GuardSwitch1 OR NOT S_GuardSwitch2 THEN
        DiagCode := 16#8002;
    ELSIF NOT S_AutoReset THEN
        DiagCode := 16#8003;
    ELSIF S_AutoReset THEN
        DiagCode := 16#8000;
    END_IF;
16#8000:
    IF NOT S_GuardSwitch1 OR NOT S_GuardSwitch2 THEN
        DiagCode := 16#8002;
    END_IF;
16#C001:
    IF NOT Reset THEN
        DiagCode := 16#8003;
    END_IF;
16#C011:
    IF NOT S_GuardSwitch1 AND NOT S_GuardSwitch2 THEN
        DiagCode := 16#8012;
    END_IF;
16#C012:
    IF NOT S_GuardSwitch1 AND NOT S_GuardSwitch2 THEN
        DiagCode := 16#8012;
    END_IF;
END_CASE;
END_IF;

CASE DiagCode OF
16#0000:
    DiscrepancyTimer(IN:=FALSE, PT:=DiscrepancyTime);
    Ready := FALSE;
    Error := FALSE;
    S_GuardMonitoring := FALSE;
16#8000:
    DiscrepancyTimer(IN:=FALSE, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := FALSE;
    S_GuardMonitoring  := TRUE;
16#8001,
16#8002,
16#8003,
16#8012,
16#8005:
    DiscrepancyTimer(IN:=FALSE, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := FALSE;
    S_GuardMonitoring := FALSE;
16#8004,
16#8014:
    Ready := TRUE;
    Error := FALSE;
    S_GuardMonitoring := FALSE;
16#C001,
16#C011,
16#C012:
    DiscrepancyTimer(IN:=FALSE, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := TRUE;
    S_GuardMonitoring := FALSE;
END_CASE;

END_FUNCTION_BLOCK
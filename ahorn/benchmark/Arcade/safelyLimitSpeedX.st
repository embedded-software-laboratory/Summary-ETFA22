FUNCTION_BLOCK SF_SafelyLimitSpeed2
 VAR_INPUT
    Activate          : BOOL;
    S_OpMode          : SAFEBOOL;
    S_Enabled         : SAFEBOOL;
    AxisID            : INT;
    MonitoringTime    : TIME;
    Reset             : BOOL;
    Acknowledge       : BOOL;      (* This is an internal input *)
 END_VAR

 VAR_OUTPUT
    Ready             : BOOL;
    S_SafetyActive    : SAFEBOOL;
    Error             : BOOL;
    DiagCode          : WORD:=16#0000;
 END_VAR

 VAR
    R_TRIGatReset: R_TRIG;
    T_1: TONX;
 END_VAR

R_TRIGatReset(CLK:=Reset);

IF NOT Activate THEN
    DiagCode := 16#0000;
END_IF;

T_1(IN:=Activate AND NOT S_OpMode, PT:=MonitoringTime);

CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
16#8000:
    IF NOT Acknowledge THEN
        DiagCode := 16#C002;
    ELSIF S_OpMode THEN
        DiagCode := 16#8012;
    ELSIF S_Enabled THEN
        DiagCode := 16#8004;
    END_IF;
16#8001:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C001;
    ELSIF R_TRIGatReset.Q AND NOT Acknowledge THEN
        DiagCode := 16#8002;
    ELSIF R_TRIGatReset.Q AND Acknowledge THEN
        DiagCode := 16#8012;
    END_IF;
16#8002:
    IF NOT S_OpMode THEN
        DiagCode := 16#8003;
    ELSIF Acknowledge THEN
        DiagCode := 16#8012;
    END_IF;
16#8003:
    IF T_1.Q THEN
        DiagCode := 16#C003;
    ELSIF S_OpMode THEN
        DiagCode := 16#8012;
    ELSIF Acknowledge AND NOT S_Enabled THEN
        DiagCode := 16#8000;
    ELSIF Acknowledge AND S_Enabled THEN
        DiagCode := 16#8004;
    END_IF;
16#8004:
    IF NOT Acknowledge THEN
        DiagCode := 16#C002;
    ELSIF S_OpMode THEN
        DiagCode := 16#8012;
    ELSIF NOT S_Enabled THEN
        DiagCode := 16#8000;
    END_IF;
16#8005:
    IF S_OpMode THEN
        DiagCode := 16#8012;
    END_IF;
16#8012:
    IF NOT Acknowledge THEN
        DiagCode := 16#8002;
    ELSIF NOT S_OpMode THEN
        DiagCode := 16#8003;
    END_IF;
16#C001:
    IF NOT Reset THEN
        DiagCode := 16#8001;
    END_IF;
16#C002:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C004;
    ELSIF R_TRIGatReset.Q THEN
        DiagCode := 16#8005;
    END_IF;
16#C003:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C005;
    ELSIF R_TRIGatReset.Q THEN
        DiagCode := 16#8005;
    END_IF;
16#C004:
    IF NOT Reset THEN
        DiagCode := 16#C002;
    END_IF;
16#C005:
    IF NOT Reset THEN
        DiagCode := 16#C003;
    END_IF;
END_CASE;


CASE DiagCode OF
16#0000:
    Ready := FALSE;
    S_SafetyActive := FALSE;
    Error := FALSE;
16#8000,
16#8004:
    Ready := TRUE;
    S_SafetyActive := TRUE;
    Error := FALSE;
16#8001,
16#8002,
16#8003,
16#8005,
16#8012:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    Error := FALSE;
16#C001,
16#C002,
16#C003,
16#C004,
16#C005:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    Error := TRUE;
END_CASE;

END_FUNCTION_BLOCK

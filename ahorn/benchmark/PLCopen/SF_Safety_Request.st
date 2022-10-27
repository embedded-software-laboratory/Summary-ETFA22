FUNCTION_BLOCK SF_Safety_Request
VAR_INPUT
        Activate        : BOOL;
        S_OpMode        : SAFEBOOL;
        S_Acknowledge   : SAFEBOOL;
        MonitoringTime  : TIME := T#0s;
        Reset           : BOOL ;
 END_VAR

 VAR_OUTPUT
        Ready : BOOL ;
        S_SafetyActive : SAFEBOOL ;
        S_SafetyRequest : SAFEBOOL ;
        Error : BOOL ;
        DiagCode : WORD:=16#0000 ;
 END_VAR

VAR
        R_TRIGatReset: R_TRIG;
        T1: TON;
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
16#8000:
    IF NOT S_Acknowledge THEN
        DiagCode := 16#C002;
    ELSIF S_OpMode THEN
        DiagCode := 16#8012;
    END_IF;
16#8001:
    IF R_TRIGatReset.Q AND NOT S_Acknowledge THEN
        DiagCode := 16#8002;
    ELSIF R_TRIGatReset.Q AND S_Acknowledge THEN
        DiagCode := 16#8012;
    END_IF;
16#8002:
    IF NOT S_OpMode THEN
        DiagCode := 16#8003;
        T1(IN:=true, PT:=MonitoringTime);
    ELSIF S_Acknowledge THEN 
        DiagCode := 16#8012;
    END_IF;
16#8003:
    IF T1.Q THEN
        DiagCode := 16#C003;
    ELSIF S_OpMode THEN
        DiagCode := 16#8012;
    ELSIF S_Acknowledge THEN
        DiagCode := 16#8000;
    END_IF;
16#8005:
    IF S_OpMode THEN
        DiagCode := 16#8012;
    END_IF;
16#8012:
    IF NOT S_Acknowledge THEN
        DiagCode := 16#8002;
    ELSIF NOT S_OpMode THEN 
        DiagCode := 16#8003;
        T1(IN:=true, PT:=MonitoringTime);
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
END_IF;

IF DiagCode <> 16#8003 THEN 
    T1(IN:=false, PT:=MonitoringTime);
END_IF;

CASE DiagCode OF
16#0000:
    Ready := FALSE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    S_SafetyActive := TRUE;
    S_SafetyRequest := FALSE;
    Error := FALSE;
16#8001:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := FALSE;
    Error := FALSE;
16#8002:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := TRUE;
    Error := FALSE;
16#8003:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := FALSE;
    Error := FALSE;
16#8005:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := FALSE;
    Error := FALSE;
16#8012:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := TRUE;
    Error := FALSE;
16#C002:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := FALSE;
    Error := TRUE;
16#C003:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := FALSE;
    Error := TRUE;
16#C004:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := FALSE;
    Error := TRUE;
16#C005:
    Ready := TRUE;
    S_SafetyActive := FALSE;
    S_SafetyRequest := FALSE;
    Error := TRUE;
END_CASE;

END_FUNCTION_BLOCK
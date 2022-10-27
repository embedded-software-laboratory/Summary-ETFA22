FUNCTION_BLOCK SF_ESPE
VAR_INPUT
        Activate : BOOL;
        S_ESPE_In : BOOL;
        S_StartReset : BOOL;
        S_AutoReset : BOOL;
        Reset : BOOL;
 END_VAR

 VAR_OUTPUT
        Ready       : BOOL;
        S_ESPE_Out  : BOOL;
        Error       : BOOL;
        DiagCode    : WORD;
 END_VAR

VAR
        R_TRIGatReset: R_TRIG;
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
    IF NOT S_StartReset THEN
        DiagCode := 16#8002;
    ELSIF S_StartReset AND NOT S_ESPE_In THEN
        DiagCode := 16#8004;
    ELSIF S_ESPE_In AND S_StartReset THEN
        DiagCode := 16#8000;
    END_IF;
16#8002:
    IF S_ESPE_In THEN
        DiagCode := 16#8003;
    END_IF;
16#8003:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C001;
    ELSIF NOT S_ESPE_In THEN
        DiagCode := 16#8002;
    ELSIF R_TRIGatReset.Q THEN
        DiagCode := 16#8000;
    END_IF;
16#C001:
    IF NOT Reset THEN
        DiagCode := 16#8003;
    END_IF;
16#8004:
    IF S_ESPE_In AND NOT S_AutoReset THEN
        DiagCode := 16#8005;
    ELSIF S_ESPE_In AND S_AutoReset THEN
        DiagCode := 16#8000;
    END_IF;
16#8005:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C002;
    ELSIF NOT S_ESPE_In THEN
        DiagCode := 16#8004;
    ELSIF R_TRIGatReset.Q OR S_AutoReset THEN
        DiagCode := 16#8000;
    END_IF;
16#C002:
    IF NOT Reset THEN
        DiagCode := 16#8005;
    END_IF;
16#8000:
    IF NOT S_ESPE_In THEN
        DiagCode := 16#8004;
    END_IF;
END_CASE;
END_IF;

CASE DiagCode OF
16#0000:
    Ready := FALSE;
    Error := FALSE;
    S_ESPE_Out := FALSE;
16#8001:
    Ready := TRUE;
    Error := FALSE;
    S_ESPE_Out := FALSE;
16#8002:
    Ready := TRUE;
    Error := FALSE;
    S_ESPE_Out := FALSE;
16#8003:
    Ready := TRUE;
    Error := FALSE;
    S_ESPE_Out := FALSE;
16#C001:
    Ready := TRUE;
    Error := TRUE;
    S_ESPE_Out := FALSE;
16#8004:
    Ready := TRUE;
    Error := FALSE;
    S_ESPE_Out := FALSE;
16#8005:
    Ready := TRUE;
    Error := FALSE;
    S_ESPE_Out := FALSE;
16#C002:
    Ready := TRUE;
    Error := TRUE;
    S_ESPE_Out := FALSE;
16#8000:
    Ready := TRUE;
    Error := FALSE;
    S_ESPE_Out := TRUE;
END_CASE;

END_FUNCTION_BLOCK
FUNCTION_BLOCK safestopX
 VAR_INPUT
    Activate          : BOOL;
    S_StopIn          : SAFEBOOL;
    AxisID            : INT;
    MonitoringTime    : TIME;
    Reset             : BOOL;
    Acknowledge       : BOOL;      (* This is an internal input *)
 END_VAR

 VAR_OUTPUT
    Ready             : BOOL;
    S_Stopped         : SAFEBOOL;
    Error             : BOOL;
    DiagCode          : WORD:=16#0000;
 END_VAR

 VAR
    R_TRIGatReset: R_TRIG;
    T_1: DCTimer;
 END_VAR

R_TRIGatReset(CLK:=Reset);

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE

T_1(IN:=Activate AND NOT S_StopIn, PT:=MonitoringTime);

CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
16#8000:
    IF NOT Acknowledge THEN
        DiagCode := 16#C002;
    ELSIF S_StopIn THEN
        DiagCode := 16#8012;
    END_IF;
16#8001:
    IF R_TRIGatReset.Q AND NOT Acknowledge THEN
        DiagCode := 16#8002;
    ELSIF R_TRIGatReset.Q AND Acknowledge THEN
        DiagCode := 16#8012;
    END_IF;
16#8002:
    IF NOT S_StopIn THEN
        DiagCode := 16#8003;
    ELSIF Acknowledge THEN
        DiagCode := 16#8012;
    END_IF;
16#8003:
    IF T_1.DiagCode = 1 THEN
        DiagCode := 16#C003;
    ELSIF S_StopIn THEN
        DiagCode := 16#8012;
    ELSIF Acknowledge THEN
        DiagCode := 16#8000;
    END_IF;
16#8005:
    IF S_StopIn THEN
        DiagCode := 16#8012;
    END_IF;
16#8012:
    IF NOT Acknowledge THEN
        DiagCode := 16#8002;
    ELSIF NOT S_StopIn THEN
        DiagCode := 16#8003;
    ELSIF Acknowledge THEN
        DiagCode := 16#8000;
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


CASE DiagCode OF
16#0000:
    Ready := FALSE;
    S_Stopped := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    S_Stopped := TRUE;
    Error := FALSE;
16#8001,
16#8002,
16#8003,
16#8005,
16#8012:
    Ready := TRUE;
    S_Stopped := FALSE;
    Error := FALSE;
16#C002,
16#C003,
16#C004,
16#C005:
    Ready := TRUE;
    S_Stopped := FALSE;
    Error := TRUE;
END_CASE;

END_FUNCTION_BLOCK

FUNCTION_BLOCK DCTimer
VAR_INPUT
  IN : BOOL;
  PT : TIME;
END_VAR
VAR
    running : BOOL;
END_VAR
VAR_TEMP
    timeout : BOOL;
END_VAR
VAR_OUTPUT
  DiagCode : WORD;
  ET : TIME;
END_VAR

  timeout := UNKNOWN_BOOL();
  
  IF NOT IN THEN
    DiagCode := 0;
    running := FALSE;
  ELSIF NOT running AND (DiagCode = 0) THEN
    running := TRUE;
  ELSIF running AND (DiagCode = 0) THEN
    IF timeout THEN
    	DiagCode := 1;
    	running := FALSE;
	ELSE
		DiagCode := 0;
		running := TRUE;
    END_IF;
    
  END_IF
  
  ET := UNKNOWN_TIME();
END_FUNCTION_BLOCK


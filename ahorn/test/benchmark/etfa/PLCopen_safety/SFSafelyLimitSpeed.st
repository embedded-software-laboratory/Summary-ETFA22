PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SOpMode : SAFEBOOL;
    SEnabled : SAFEBOOL;
    AxisID : INT;
    MonitoringTime : TIME;
    Reset : BOOL;
    Acknowledge : BOOL;      (* This is an internal input *)
END_VAR
VAR
    SFSafelyLimitSpeed : SFSafelyLimitSpeed;
END_VAR
SFSafelyLimitSpeed(Activate:=Activate,SOpMode:=SOpMode,SEnabled:=SEnabled,AxisID:=AxisID,MonitoringTime:=MonitoringTime,
Reset:=Reset,Acknowledge:=Acknowledge);
END_PROGRAM

FUNCTION_BLOCK SFSafelyLimitSpeed
VAR_INPUT
    Activate : BOOL;
    SOpMode : SAFEBOOL;
    SEnabled : SAFEBOOL;
    AxisID : INT;
    MonitoringTime : TIME;
    Reset : BOOL;
    Acknowledge : BOOL;      (* This is an internal input *)
END_VAR
VAR
    IN : BOOL;
    PT : TIME;
    running : BOOL;
    Q : BOOL;
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL;
    SSafetyActive : SAFEBOOL;
    Error : BOOL;
    DiagCode : WORD;
END_VAR
RTRIGatResetQ := Reset AND NOT RTRIGatResetM;
RTRIGatResetM := Reset;

IF NOT Activate THEN
    DiagCode := 16#0000;
END_IF;
IN:=Activate AND NOT SOpMode;
PT:=MonitoringTime;
IF NOT IN THEN
    Q := FALSE;
    running := FALSE;
ELSIF NOT running AND NOT Q THEN
    running := TRUE;
ELSIF running AND NOT Q THEN
    Q := NONDETERMINISTIC_BOOL();
    running := NOT Q;
END_IF;
CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
16#8000:
    IF NOT Acknowledge THEN
        DiagCode := 16#C002;
    ELSIF SOpMode THEN
        DiagCode := 16#8012;
    ELSIF SEnabled THEN
        DiagCode := 16#8004;
    END_IF;
16#8001:
    IF Reset AND NOT RTRIGatResetQ THEN
        DiagCode := 16#C001;
    ELSIF RTRIGatResetQ AND NOT Acknowledge THEN
        DiagCode := 16#8002;
    ELSIF RTRIGatResetQ AND Acknowledge THEN
        DiagCode := 16#8012;
    END_IF;
16#8002:
    IF NOT SOpMode THEN
        DiagCode := 16#8003;
    ELSIF Acknowledge THEN
        DiagCode := 16#8012;
    END_IF;
16#8003:
    IF Q THEN
        DiagCode := 16#C003;
    ELSIF SOpMode THEN
        DiagCode := 16#8012;
    ELSIF Acknowledge AND NOT SEnabled THEN
        DiagCode := 16#8000;
    ELSIF Acknowledge AND SEnabled THEN
        DiagCode := 16#8004;
    END_IF;
16#8004:
    IF NOT Acknowledge THEN
        DiagCode := 16#C002;
    ELSIF SOpMode THEN
        DiagCode := 16#8012;
    ELSIF NOT SEnabled THEN
        DiagCode := 16#8000;
    END_IF;
16#8005:
    IF SOpMode THEN
        DiagCode := 16#8012;
    END_IF;
16#8012:
    IF NOT Acknowledge THEN
        DiagCode := 16#8002;
    ELSIF NOT SOpMode THEN
        DiagCode := 16#8003;
    END_IF;
16#C001:
    IF NOT Reset THEN
        DiagCode := 16#8001;
    END_IF;
16#C002:
    IF Reset AND NOT RTRIGatResetQ THEN
        DiagCode := 16#C004;
    ELSIF RTRIGatResetQ THEN
        DiagCode := 16#8005;
    END_IF;
16#C003:
    IF Reset AND NOT RTRIGatResetQ THEN
        DiagCode := 16#C005;
    ELSIF RTRIGatResetQ THEN
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
    SSafetyActive := FALSE;
    Error := FALSE;
16#8000,
16#8004:
    Ready := TRUE;
    SSafetyActive := TRUE;
    Error := FALSE;
16#8001,
16#8002,
16#8003,
16#8005,
16#8012:
    Ready := TRUE;
    SSafetyActive := FALSE;
    Error := FALSE;
16#C001,
16#C002,
16#C003,
16#C004,
16#C005:
    Ready := TRUE;
    SSafetyActive := FALSE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK

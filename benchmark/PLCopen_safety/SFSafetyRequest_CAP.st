PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SOpMode : SAFEBOOL;
    SAcknowledge : SAFEBOOL;
    MonitoringTime : TIME;
    Reset : BOOL;
END_VAR
VAR
    SFSafetyRequest : SFSafetyRequest;
END_VAR
SFSafetyRequest(Activate:=Activate,SOpMode:=SOpMode,SAcknowledge:=SAcknowledge,MonitoringTime:=MonitoringTime,Reset:=Reset);
END_PROGRAM

FUNCTION_BLOCK SFSafetyRequest
VAR_INPUT
    Activate : BOOL;
    SOpMode : SAFEBOOL;
    SAcknowledge : SAFEBOOL;
    MonitoringTime : TIME;
    Reset : BOOL;
END_VAR
VAR
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
    IN : BOOL;
    PT : TIME;
    running : BOOL;
    Q : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL;
    SSafetyActive : SAFEBOOL;
    SSafetyRequest : SAFEBOOL;
    Error : BOOL;
    DiagCode : WORD;
END_VAR
RTRIGatResetQ := Reset AND NOT RTRIGatResetM;
RTRIGatResetM := Reset;

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
    16#0000:
        IF Activate THEN
            DiagCode := 16#8001;
        END_IF;
    16#8000:
        IF NOT SAcknowledge THEN
            DiagCode := 16#C002;
        ELSIF SOpMode THEN
            DiagCode := change(16#8012, 16#8003);
        END_IF;
    16#8001:
        IF RTRIGatResetQ AND NOT SAcknowledge THEN
            DiagCode := 16#8002;
        ELSIF RTRIGatResetQ AND SAcknowledge THEN
            DiagCode := 16#8012;
        END_IF;
    16#8002:
        IF NOT SOpMode THEN
            DiagCode := 16#8003;
        ELSIF SAcknowledge THEN
            DiagCode := 16#8012;
        END_IF;
    16#8003:
        IF Q THEN
            DiagCode := 16#C003;
        ELSIF SOpMode THEN
            DiagCode := 16#8012;
        ELSIF SAcknowledge THEN
            DiagCode := 16#8000;
        END_IF;
    16#8005:
        IF SOpMode THEN
            DiagCode := 16#8012;
        END_IF;
    16#8012:
        IF NOT SAcknowledge THEN
            DiagCode := 16#8002;
        ELSIF NOT SOpMode THEN
            DiagCode := 16#8003;
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
END_IF;
IF DiagCode <> 16#8003 THEN 
    IN:=FALSE;
    PT:=MonitoringTime;
    Q := FALSE;
    running := FALSE;
ELSE
    IN:=TRUE;
    PT:=MonitoringTime;
    IF NOT running AND NOT Q THEN
        running := TRUE;
    ELSIF running AND NOT Q THEN
        Q := NONDETERMINISTIC_BOOL();
        running := NOT Q;
    END_IF;
END_IF;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    SSafetyActive := FALSE;
    SSafetyRequest := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    SSafetyActive := TRUE;
    SSafetyRequest := FALSE;
    Error := FALSE;
16#8001:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := FALSE;
    Error := FALSE;
16#8002:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := TRUE;
    Error := FALSE;
16#8003:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := FALSE;
    Error := FALSE;
16#8005:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := FALSE;
    Error := FALSE;
16#8012:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := TRUE;
    Error := FALSE;
16#C002:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := FALSE;
    Error := TRUE;
16#C003:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := FALSE;
    Error := TRUE;
16#C004:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := FALSE;
    Error := TRUE;
16#C005:
    Ready := TRUE;
    SSafetyActive := FALSE;
    SSafetyRequest := FALSE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK

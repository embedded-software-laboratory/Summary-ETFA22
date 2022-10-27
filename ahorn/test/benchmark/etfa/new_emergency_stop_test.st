PROGRAM Test
VAR_INPUT
    Ready : BOOL;
    SEquivalentOut : BOOL;
    S0Reset : BOOL;
END_VAR
VAR
    SFEmergencyStop1 : SFEmergencyStop;
END_VAR
SFEmergencyStop1(Activate:=Ready,
                 SEStopIn:=SEquivalentOut,
                 SStartReset:=FALSE,
                 SAutoReset:=FALSE, Reset:=S0Reset);
END_PROGRAM

FUNCTION_BLOCK SFEmergencyStop
VAR_INPUT
    Activate : BOOL;
    SEStopIn : BOOL;
    SStartReset : BOOL;
    SAutoReset : BOOL;
    Reset : BOOL;
END_VAR
VAR
    RTrigCLK : BOOL;
    RTrigM : BOOL;
    RTrigQ : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL;
    SEStopOut : BOOL;
    Error : BOOL;
    DiagCode : WORD;
END_VAR
RTrigQ := Reset AND NOT RTrigM;
RTrigM := Reset;
IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
    16#0000:
        IF Activate THEN
            DiagCode := change(16#8001, 16#8001);
        END_IF;
    16#8001:
        IF change(NOT SStartReset, FALSE) THEN
            DiagCode := 16#8002;
        ELSIF SStartReset AND NOT SEStopIn THEN
            DiagCode := 16#8004;
        ELSIF SEStopIn AND SStartReset THEN
            DiagCode := 16#8000;
        END_IF;
    16#8002:
        IF SEStopIn THEN
            DiagCode := 16#8003;
        END_IF;
    16#8003:
        IF Reset AND NOT RTrigQ THEN
            DiagCode := 16#C001;
        ELSIF NOT SEStopIn THEN
            DiagCode := 16#8002;
        ELSIF RTrigQ THEN
            DiagCode := 16#8000;
        END_IF;
    16#C001:
        IF NOT Reset THEN
            DiagCode := 16#8003;
        END_IF;
    16#8004:
        IF SEStopIn AND NOT SAutoReset THEN
            DiagCode := 16#8005;
        ELSIF SEStopIn AND SAutoReset THEN
            DiagCode := 16#8000;
        END_IF;
    16#8005:
        IF Reset AND NOT RTrigQ THEN
            DiagCode := 16#C002;
        ELSIF NOT SEStopIn THEN
            DiagCode := 16#8004;
        ELSIF RTrigQ OR SAutoReset THEN
            DiagCode := 16#8000;
        END_IF;
    16#C002:
        IF NOT Reset THEN
            DiagCode := 16#8005;
        END_IF;
    16#8000:
        IF NOT SEStopIn THEN
            DiagCode := 16#8004;
        END_IF;
    END_CASE;
END_IF;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    Error := FALSE;
    SEStopOut := FALSE;
16#8001:
    Ready := TRUE;
    Error := FALSE;
    SEStopOut := FALSE;
16#8002:
    Ready := TRUE;
    Error := FALSE;
    SEStopOut := FALSE;
16#8003:
    Ready := TRUE;
    Error := FALSE;
    SEStopOut := FALSE;
16#C001:
    Ready := TRUE;
    Error := TRUE;
    SEStopOut := FALSE;
16#8004:
    Ready := TRUE;
    Error := FALSE;
    SEStopOut := FALSE;
16#8005:
    Ready := TRUE;
    Error := FALSE;
    SEStopOut := FALSE;
16#C002:
    Ready := TRUE;
    Error := TRUE;
    SEStopOut := FALSE;
16#8000:
    Ready := TRUE;
    Error := FALSE;
    SEStopOut := TRUE;
END_CASE;
END_FUNCTION_BLOCK
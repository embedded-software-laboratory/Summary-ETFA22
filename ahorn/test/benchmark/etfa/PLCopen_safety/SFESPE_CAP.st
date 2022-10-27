PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SESPEIn : BOOL;
    SStartReset : BOOL;
    SAutoReset : BOOL;
    Reset : BOOL;
END_VAR
VAR
    SFESPE : SFESPE;
END_VAR
SFESPE(Activate:=Activate,SESPEIn:=SESPEIn,SStartReset:=SStartReset,SAutoReset:=SAutoReset,Reset:=Reset);
END_PROGRAM

FUNCTION_BLOCK SFESPE
VAR_INPUT
    Activate : BOOL;
    SESPEIn : BOOL;
    SStartReset : BOOL;
    SAutoReset : BOOL;
    Reset : BOOL;
END_VAR
VAR
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL;
    SESPEOut : BOOL;
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
            DiagCode := change(16#8001, 16#8004);
        END_IF;
    16#8001:
        IF NOT SStartReset THEN
            DiagCode := 16#8002;
        ELSIF SStartReset AND NOT SESPEIn THEN
            DiagCode := 16#8004;
        ELSIF SESPEIn AND SStartReset THEN
            DiagCode := 16#8000;
        END_IF;
    16#8002:
        IF SESPEIn THEN
            DiagCode := 16#8003;
        END_IF;
    16#8003:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C001;
        ELSIF NOT SESPEIn THEN
            DiagCode := 16#8002;
        ELSIF RTRIGatResetQ THEN
            DiagCode := 16#8000;
        END_IF;
    16#C001:
        IF NOT Reset THEN
            DiagCode := 16#8003;
        END_IF;
    16#8004:
        IF SESPEIn AND NOT SAutoReset THEN
            DiagCode := 16#8005;
        ELSIF SESPEIn AND SAutoReset THEN
            DiagCode := 16#8000;
        END_IF;
    16#8005:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C002;
        ELSIF NOT SESPEIn THEN
            DiagCode := 16#8004;
        ELSIF RTRIGatResetQ OR SAutoReset THEN
            DiagCode := 16#8000;
        END_IF;
    16#C002:
        IF NOT Reset THEN
            DiagCode := 16#8005;
        END_IF;
    16#8000:
        IF NOT SESPEIn THEN
            DiagCode := change(16#8004, 16#8000);
        END_IF;
    END_CASE;
END_IF;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    Error := FALSE;
    SESPEOut := FALSE;
16#8001:
    Ready := TRUE;
    Error := FALSE;
    SESPEOut := FALSE;
16#8002:
    Ready := TRUE;
    Error := FALSE;
    SESPEOut := FALSE;
16#8003:
    Ready := TRUE;
    Error := FALSE;
    SESPEOut := FALSE;
16#C001:
    Ready := TRUE;
    Error := TRUE;
    SESPEOut := FALSE;
16#8004:
    Ready := TRUE;
    Error := FALSE;
    SESPEOut := FALSE;
16#8005:
    Ready := TRUE;
    Error := FALSE;
    SESPEOut := FALSE;
16#C002:
    Ready := TRUE;
    Error := TRUE;
    SESPEOut := FALSE;
16#8000:
    Ready := TRUE;
    Error := FALSE;
    SESPEOut := TRUE;
END_CASE;
END_FUNCTION_BLOCK
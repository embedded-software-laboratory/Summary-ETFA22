PROGRAM Main
VAR_INPUT
    Activate : BOOL ;
    SSafeControl : SAFEBOOL ;
    ProcessControl : BOOL ;
    StaticControl : BOOL ;
    SStartReset : SAFEBOOL ;
    SAutoReset	: SAFEBOOL ;
    Reset : BOOL ;
END_VAR
VAR
    SFOutControl : SFOutControl;
END_VAR
SFOutControl(Activate:=Activate,SSafeControl:=SSafeControl,ProcessControl:=ProcessControl,StaticControl:=StaticControl,
SStartReset:=SStartReset,SAutoReset:=SAutoReset,Reset:=Reset);
END_PROGRAM

FUNCTION_BLOCK SFOutControl
VAR_INPUT
    Activate : BOOL ;
    SSafeControl : SAFEBOOL ;
    ProcessControl : BOOL ;	
    StaticControl : BOOL ;
    SStartReset : SAFEBOOL ;
    SAutoReset	: SAFEBOOL ; 
    Reset : BOOL ;
END_VAR
VAR
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
    RTRIGatProcessControlQ : BOOL;
    RTRIGatProcessControlM : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL ;
    SOutControl : SAFEBOOL ;
    Error : BOOL ;
    DiagCode : WORD:=16#0000 ;
END_VAR
RTRIGatResetQ := Reset AND NOT RTRIGatResetM;
RTRIGatResetM := Reset;

RTRIGatProcessControlQ := ProcessControl AND NOT RTRIGatProcessControlM;
RTRIGatProcessControlM := ProcessControl;

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
    16#0000:
        IF Activate THEN
            DiagCode := 16#8001;
        END_IF;
    16#8000:
        IF NOT SSafeControl THEN
            DiagCode := 16#8002;
        ELSIF NOT ProcessControl THEN
            DiagCode := 16#8010;
        END_IF;
    16#8001:
        IF Reset AND NOT RTRIGatResetQ AND NOT SStartReset THEN
            DiagCode := 16#C001;
        ELSIF RTRIGatResetQ AND RTRIGatProcessControlQ THEN
            DiagCode := 16#C111;
        ELSIF RTRIGatResetQ OR SStartReset THEN
            DiagCode := 16#8010;
        END_IF;
    16#8002:
        IF SSafeControl THEN
            DiagCode := 16#8003;
        END_IF;
    16#8003:
        IF NOT SSafeControl THEN
            DiagCode := 16#8002;
        ELSIF Reset AND NOT RTRIGatResetQ AND NOT SAutoReset THEN
            DiagCode := 16#C002;
        ELSIF RTRIGatResetQ AND RTRIGatProcessControlQ THEN
            DiagCode := 16#C211;
        ELSIF RTRIGatResetQ OR SAutoReset THEN
            DiagCode := 16#8010;
        END_IF;
    16#8010:
        IF NOT SSafeControl THEN
            DiagCode := 16#8002;
        ELSIF NOT RTRIGatProcessControlQ AND ProcessControl AND NOT StaticControl THEN
            DiagCode := 16#C010;
        ELSIF SSafeControl AND (RTRIGatProcessControlQ OR (StaticControl AND ProcessControl)) THEN
            DiagCode := 16#8000;
        END_IF;
    16#C001:
        IF NOT Reset THEN
            DiagCode := 16#8001;
        END_IF;
    16#C002:
        IF NOT Reset THEN
            DiagCode := 16#8003;
        END_IF;
    16#C010:
        IF NOT ProcessControl THEN
            DiagCode := 16#8010;
        END_IF;
    16#C111:
        IF NOT Reset THEN
            DiagCode := 16#8001;
        END_IF;
    16#C211:
        IF NOT Reset THEN
            DiagCode := 16#8003;
        END_IF;
    END_CASE;
END_IF;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    SOutControl := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    SOutControl := TRUE;
    Error := FALSE;
16#8001, 16#8002, 16#8003, 16#8010:
    Ready := TRUE;
    SOutControl := FALSE;
    Error := FALSE;
16#C001, 16#C002, 16#C010, 16#C111, 16#C211:
    Ready := TRUE;
    SOutControl := FALSE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK
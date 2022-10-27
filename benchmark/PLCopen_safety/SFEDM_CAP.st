PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SOutControl	: SAFEBOOL;
    SEDM1 : SAFEBOOL;
    SEDM2 : SAFEBOOL;
    MonitoringTime : TIME;
    SStartReset	: SAFEBOOL;
    Reset : BOOL;
END_VAR
VAR
    SFEDM : SFEDM;
END_VAR
SFEDM(Activate:=Activate,SOutControl:=SOutControl,SEDM1:=SEDM1,SEDM2:=SEDM2,MonitoringTime:=MonitoringTime,
SStartReset:=SStartReset,Reset:=Reset);
END_PROGRAM

FUNCTION_BLOCK SFEDM
VAR_INPUT
    Activate : BOOL ;
    SOutControl	: SAFEBOOL ;
    SEDM1 : SAFEBOOL ;
    SEDM2 : SAFEBOOL ;
    MonitoringTime : TIME;
    SStartReset	: SAFEBOOL ;
    Reset : BOOL ;
END_VAR
VAR
    IN : BOOL;
    PT : TIME;
    running : BOOL;
    Q : BOOL;
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
    RTRIGatOutControlQ : BOOL;
    RTRIGatOutControlM : BOOL;
    RTRIGatEDM1Q : BOOL;
    RTRIGatEDM1M : BOOL;
    RTRIGatEDM2Q : BOOL;
    RTRIGatEDM2M : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL ;
    SEDMOut	: SAFEBOOL ;
    Error : BOOL ;
    DiagCode : WORD:=16#0000 ;
END_VAR
(* Rising edge detection *)
RTRIGatResetQ := Reset AND NOT RTRIGatResetM;
RTRIGatResetM := Reset;

RTRIGatOutControlQ := SOutControl AND NOT RTRIGatOutControlM;
RTRIGatOutControlM := SOutControl;

RTRIGatEDM1Q := SEDM1 AND NOT RTRIGatEDM1M;
RTRIGatEDM1M := SEDM1;

RTRIGatEDM2Q := SEDM2 AND NOT RTRIGatEDM2M;
RTRIGatEDM2M := SEDM2;

IF NOT Activate THEN
    DiagCode := change(16#0000, 16#8001);
ELSE
    CASE DiagCode OF
    16#0000:
        IF Activate THEN
            DiagCode := 16#8001;
        END_IF;
    16#8000:
        IF Q AND SEDM1 AND NOT SEDM2 THEN
            DiagCode := 16#C070;
        ELSIF Q AND NOT SEDM1 AND SEDM2 THEN
            DiagCode := 16#C080;
        ELSIF Q AND SEDM1 AND SEDM2 THEN
            DiagCode := 16#C090;
        ELSIF NOT SOutControl THEN
            DiagCode := 16#8010;
            IN:=FALSE;
            Q := FALSE;
            running := FALSE;
        END_IF;
    16#8001:
        IF Reset AND NOT RTRIGatResetQ AND NOT SStartReset THEN
            DiagCode := 16#C001;
        ELSIF RTRIGatResetQ AND RTRIGatOutControlQ AND NOT SStartReset THEN
            DiagCode := 16#C111;
        ELSIF RTRIGatResetQ OR SStartReset THEN
            DiagCode := 16#8010;
            IN:=FALSE;
            Q := FALSE;
            running := FALSE;
        END_IF;
    16#8010:
        IF SOutControl AND NOT SEDM1 AND SEDM2 THEN
            DiagCode := 16#C010;
        ELSIF SOutControl AND SEDM1 AND NOT SEDM2 THEN
            DiagCode := 16#C020;
        ELSIF SOutControl AND NOT SEDM1 AND NOT SEDM2 THEN
            DiagCode := 16#C030;
        ELSIF Q AND NOT SEDM1 AND SEDM2 THEN
            DiagCode := 16#C040;
        ELSIF Q AND SEDM1 AND NOT SEDM2 THEN
            DiagCode := 16#C050;
        ELSIF Q AND NOT SEDM1 AND NOT SEDM2 THEN
            DiagCode := 16#C060;
        ELSIF SOutControl THEN
            DiagCode := 16#8000;
            IN:=FALSE;
            Q := FALSE;
            running := FALSE;
        END_IF;
    16#C001:
        IF NOT Reset THEN
            DiagCode := 16#8001;
        END_IF;
    16#C010, 16#C020, 16#C030:
        IF (Reset AND NOT RTRIGatResetQ AND SEDM1 AND SEDM2) OR (RTRIGatResetQ AND RTRIGatEDM1Q AND NOT RTRIGatEDM2Q) THEN
            DiagCode := 16#C011;
        ELSIF (Reset AND NOT RTRIGatResetQ AND SEDM1 AND SEDM2) OR (RTRIGatResetQ AND NOT RTRIGatEDM1Q AND RTRIGatEDM2Q) THEN
            DiagCode := 16#C021;
        ELSIF (Reset AND NOT RTRIGatResetQ AND SEDM1 AND SEDM2) OR (RTRIGatResetQ AND RTRIGatEDM1Q AND RTRIGatEDM2Q) THEN
            DiagCode := 16#C031;
        ELSIF RTRIGatResetQ AND SEDM1 AND SEDM2 THEN
            DiagCode := 16#8010;
            IN:=FALSE;
            Q := FALSE;
            running := FALSE;
        END_IF;
    16#C011:
        IF NOT Reset THEN
            DiagCode := 16#C010;
        END_IF;
    16#C021:
        IF NOT Reset THEN
            DiagCode := 16#C020;
        END_IF;
    16#C031:
        IF NOT Reset THEN
            DiagCode := 16#C030;
        END_IF;
    16#C040, 16#C050, 16#C060:
        IF (Reset AND NOT RTRIGatResetQ AND SEDM1 AND SEDM2) OR (RTRIGatResetQ AND RTRIGatEDM1Q AND NOT RTRIGatEDM2Q) THEN
            DiagCode := 16#C041;
        ELSIF (Reset AND NOT RTRIGatResetQ AND SEDM1 AND SEDM2) OR (RTRIGatResetQ AND NOT RTRIGatEDM1Q AND RTRIGatEDM2Q) THEN
            DiagCode := 16#C051;
        ELSIF (Reset AND NOT RTRIGatResetQ AND SEDM1 AND SEDM2) OR (RTRIGatResetQ AND RTRIGatEDM1Q AND RTRIGatEDM2Q) THEN
            DiagCode := 16#C061;
        ELSIF RTRIGatResetQ AND SEDM1 AND SEDM2 THEN
            DiagCode := 16#8010;
            IN:=FALSE;
            Q := FALSE;
            running := FALSE;
        END_IF;
    16#C041:
        IF NOT Reset THEN
            DiagCode := 16#C040;
        END_IF;
    16#C051:
        IF NOT Reset THEN
            DiagCode := 16#C050;
        END_IF;
    16#C061:
        IF NOT Reset THEN
            DiagCode := 16#C060;
        END_IF;
    16#C070:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C071;
        ELSIF RTRIGatResetQ AND NOT (RTRIGatEDM1Q OR RTRIGatEDM2Q) THEN
            DiagCode := 16#8010;
            IN:=FALSE;
            Q := FALSE;
            running := FALSE;
        END_IF;
    16#C080:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C081;
        ELSIF RTRIGatResetQ AND NOT (RTRIGatEDM1Q OR RTRIGatEDM2Q) THEN
            DiagCode := 16#8010;
            IN:=FALSE;
            Q := FALSE;
            running := FALSE;
        END_IF;
    16#C090:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C091;
        ELSIF RTRIGatResetQ AND NOT (RTRIGatEDM1Q OR RTRIGatEDM2Q) THEN
            DiagCode := 16#8010;
            IN:=FALSE;
            Q := FALSE;
            running := FALSE;
        END_IF;
    16#C071:
        IF NOT Reset THEN
            DiagCode := 16#C070;
        END_IF;
    16#C081:
        IF NOT Reset THEN
            DiagCode := 16#C080;
        END_IF;
    16#C091:
        IF NOT Reset THEN
            DiagCode := 16#C090;
        END_IF;
    16#C111:
        IF NOT Reset THEN
            DiagCode := 16#8001;
        END_IF;
    END_CASE;
END_IF;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    SEDMOut := FALSE;
    Error := FALSE;
16#8001:
    Ready := TRUE;
    SEDMOut := FALSE;
    Error := FALSE;
16#8010:
    Ready := TRUE;
    SEDMOut := FALSE;
    Error := FALSE;
    IN:=TRUE;
    PT:=MonitoringTime;
    IF NOT running AND NOT Q THEN
        running := TRUE;
    ELSIF running AND NOT Q THEN
        Q := NONDETERMINISTIC_BOOL();
        running := NOT Q;
    END_IF;
16#8000:
    Ready := TRUE;
    SEDMOut := TRUE;
    Error := FALSE;
    IN:=TRUE;
    PT:=MonitoringTime;
    IF NOT running AND NOT Q THEN
        running := TRUE;
    ELSIF running AND NOT Q THEN
        Q := NONDETERMINISTIC_BOOL();
        running := NOT Q;
    END_IF;
16#C001, 16#C010, 16#C011, 16#C020, 16#C021, 16#C030, 16#C031, 16#C040, 16#C041, 16#C050, 16#C051, 16#C060, 16#C061, 16#C070, 16#C071, 16#C080, 16#C081, 16#C090, 16#C091, 16#C111:
    Ready := TRUE;
    SEDMOut := FALSE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK

FUNCTION_BLOCK RTRIG
VAR_INPUT
    CLK : BOOL;
END_VAR
VAR
    M : BOOL;
END_VAR
VAR_OUTPUT
    Q : BOOL;
END_VAR
    Q := CLK AND NOT M;
    M := CLK;
END_FUNCTION_BLOCK
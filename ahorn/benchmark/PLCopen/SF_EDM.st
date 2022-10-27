FUNCTION_BLOCK SF_EDM
VAR_INPUT
	Activate		: BOOL ;
	S_OutControl	: SAFEBOOL ;
	S_EDM1			: SAFEBOOL ;
	S_EDM2			: SAFEBOOL ;
	MonitoringTime	: TIME;
	S_StartReset	: SAFEBOOL ;
	Reset		  	: BOOL ;
END_VAR

VAR_OUTPUT
	Ready		: BOOL ;
	S_EDM_Out	: SAFEBOOL ;
	Error	    : BOOL ;
	DiagCode	: WORD:=16#0000 ;
END_VAR

VAR
	R_TRIGatReset	    : R_TRIG ;
	R_TRIGatOutControl	: R_TRIG ;
	R_TRIGatEDM1	 	: R_TRIG ;
	R_TRIGatEDM2	 	: R_TRIG ;
	T_1	: TON ;
END_VAR

(* Rising edge detection *)
R_TRIGatReset(CLK:=Reset);
R_TRIGatOutControl(CLK:=S_OutControl);
R_TRIGatEDM1(CLK:=S_EDM1);
R_TRIGatEDM2(CLK:=S_EDM2);

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
    16#0000:
        IF Activate THEN
            DiagCode := 16#8001;
        END_IF;
    16#8000:
        IF T_1.Q AND S_EDM1 AND NOT S_EDM2 THEN
            DiagCode := 16#C070;
        ELSIF T_1.Q AND NOT S_EDM1 AND S_EDM2 THEN
            DiagCode := 16#C080;
        ELSIF T_1.Q AND S_EDM1 AND S_EDM2 THEN
            DiagCode := 16#C090;
        ELSIF NOT S_OutControl THEN
            DiagCode := 16#8010;
            T_1(IN:=FALSE);
        END_IF;        
    16#8001:
        IF Reset AND NOT R_TRIGatReset.Q AND NOT S_StartReset THEN
            DiagCode := 16#C001;
        ELSIF R_TRIGatReset.Q AND R_TRIGatOutControl.Q AND NOT S_StartReset THEN
            DiagCode := 16#C111;
        ELSIF R_TRIGatReset.Q OR S_StartReset THEN
            DiagCode := 16#8010;
            T_1(IN:=FALSE);
        END_IF;
    16#8010:
        IF S_OutControl AND NOT S_EDM1 AND S_EDM2 THEN
            DiagCode := 16#C010;
        ELSIF S_OutControl AND S_EDM1 AND NOT S_EDM2 THEN
            DiagCode := 16#C020;
        ELSIF S_OutControl AND NOT S_EDM1 AND NOT S_EDM2 THEN
            DiagCode := 16#C030;
        ELSIF T_1.Q AND NOT S_EDM1 AND S_EDM2 THEN
            DiagCode := 16#C040;
        ELSIF T_1.Q AND S_EDM1 AND NOT S_EDM2 THEN
            DiagCode := 16#C050;
        ELSIF T_1.Q AND NOT S_EDM1 AND NOT S_EDM2 THEN
            DiagCode := 16#C060;
        ELSIF S_OutControl THEN
            DiagCode := 16#8000;
            T_1(IN:=FALSE);
        END_IF;
    16#C001:
        IF NOT Reset THEN
            DiagCode := 16#8001;
        END_IF;
    16#C010, 16#C020, 16#C030:
        IF (Reset AND NOT R_TRIGatReset.Q AND S_EDM1 AND S_EDM2) OR (R_TRIGatReset.Q AND R_TRIGatEDM1.Q AND NOT R_TRIGatEDM2.Q) THEN
            DiagCode := 16#C011;
        ELSIF (Reset AND NOT R_TRIGatReset.Q AND S_EDM1 AND S_EDM2) OR (R_TRIGatReset.Q AND NOT R_TRIGatEDM1.Q AND R_TRIGatEDM2.Q) THEN
            DiagCode := 16#C021;
        ELSIF (Reset AND NOT R_TRIGatReset.Q AND S_EDM1 AND S_EDM2) OR (R_TRIGatReset.Q AND R_TRIGatEDM1.Q AND R_TRIGatEDM2.Q) THEN
            DiagCode := 16#C031;
        ELSIF R_TRIGatReset.Q AND S_EDM1 AND S_EDM2 THEN
            DiagCode := 16#8010;
            T_1(IN:=FALSE);
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
        IF (Reset AND NOT R_TRIGatReset.Q AND S_EDM1 AND S_EDM2) OR (R_TRIGatReset.Q AND R_TRIGatEDM1.Q AND NOT R_TRIGatEDM2.Q) THEN
            DiagCode := 16#C041;
        ELSIF (Reset AND NOT R_TRIGatReset.Q AND S_EDM1 AND S_EDM2) OR (R_TRIGatReset.Q AND NOT R_TRIGatEDM1.Q AND R_TRIGatEDM2.Q) THEN
            DiagCode := 16#C051;
        ELSIF (Reset AND NOT R_TRIGatReset.Q AND S_EDM1 AND S_EDM2) OR (R_TRIGatReset.Q AND R_TRIGatEDM1.Q AND R_TRIGatEDM2.Q) THEN
            DiagCode := 16#C061;
        ELSIF R_TRIGatReset.Q AND S_EDM1 AND S_EDM2 THEN
            DiagCode := 16#8010;
            T_1(IN:=FALSE);
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
        IF Reset AND NOT R_TRIGatReset.Q THEN
            DiagCode := 16#C071;
        ELSIF R_TRIGatReset.Q AND NOT (R_TRIGatEDM1.Q OR R_TRIGatEDM2.Q) THEN
            DiagCode := 16#8010;
            T_1(IN:=FALSE);
        END_IF;
    16#C080:
        IF Reset AND NOT R_TRIGatReset.Q THEN
            DiagCode := 16#C081;
        ELSIF R_TRIGatReset.Q AND NOT (R_TRIGatEDM1.Q OR R_TRIGatEDM2.Q) THEN
            DiagCode := 16#8010;
            T_1(IN:=FALSE);
        END_IF;
    16#C090:
        IF Reset AND NOT R_TRIGatReset.Q THEN
            DiagCode := 16#C091;
        ELSIF R_TRIGatReset.Q AND NOT (R_TRIGatEDM1.Q OR R_TRIGatEDM2.Q) THEN
            DiagCode := 16#8010;
            T_1(IN:=FALSE);
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
        S_EDM_Out := FALSE;
        Error := FALSE;
    16#8001:
        Ready := TRUE;
        S_EDM_Out := FALSE;
        Error := FALSE;
    16#8010:
        Ready := TRUE;
        S_EDM_Out := FALSE;
        Error := FALSE;
        T_1(IN:=TRUE, PT:=MonitoringTime);
    16#8000:
        Ready := TRUE;
        S_EDM_Out := TRUE;
        Error := FALSE;
        T_1(IN:=TRUE, PT:=MonitoringTime);
    16#C001, 16#C010, 16#C011, 16#C020, 16#C021, 16#C030, 16#C031, 16#C040, 16#C041, 16#C050, 16#C051, 16#C060, 16#C061, 16#C070, 16#C071, 16#C080, 16#C081, 16#C090, 16#C091, 16#C111:
        Ready := TRUE;
        S_EDM_Out := FALSE;
        Error := TRUE;
END_CASE;

END_FUNCTION_BLOCK
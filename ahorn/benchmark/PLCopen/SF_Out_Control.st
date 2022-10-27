FUNCTION_BLOCK SF_Out_Control
VAR_INPUT
	Activate		 	: BOOL ;
	S_SafeControl		: SAFEBOOL ;
	ProcessControl		: BOOL ;	
	StaticControl		: BOOL ;
	S_StartReset		: SAFEBOOL ;
	S_AutoReset			: SAFEBOOL ; 
	Reset				: BOOL ;
END_VAR

VAR_OUTPUT
	Ready				: BOOL ;
	S_OutControl		: SAFEBOOL ;
	Error	    		: BOOL ;
	DiagCode			: WORD:=16#0000 ;
END_VAR

VAR
	R_TRIGatReset	 	    : R_TRIG ;
	R_TRIGatProcessControl  : R_TRIG ;
END_VAR

R_TRIGatReset(CLK:=Reset);
R_TRIGatProcessControl(CLK:=ProcessControl);

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
        16#0000:
            IF Activate THEN
                DiagCode := 16#8001;
            END_IF;
        16#8000:
            IF NOT S_SafeControl THEN
                DiagCode := 16#8002;
            ELSIF NOT ProcessControl THEN
                DiagCode := 16#8010;       
            END_IF;
        16#8001:
            IF Reset AND NOT R_TRIGatReset.Q AND NOT S_StartReset THEN
                DiagCode := 16#C001;
            ELSIF R_TRIGatReset.Q AND R_TRIGatProcessControl.Q THEN
                DiagCode := 16#C111;
            ELSIF R_TRIGatReset.Q OR S_StartReset THEN
                DiagCode := 16#8010;
            END_IF;
        16#8002:
            IF S_SafeControl THEN
                DiagCode := 16#8003;
            END_IF;
        16#8003:
            IF NOT S_SafeControl THEN
                DiagCode := 16#8002;
            ELSIF Reset AND NOT R_TRIGatReset.Q AND NOT S_AutoReset THEN
                DiagCode := 16#C002;
            ELSIF R_TRIGatReset.Q AND R_TRIGatProcessControl.Q THEN
                DiagCode := 16#C211;
            ELSIF R_TRIGatReset.Q OR S_AutoReset THEN
                DiagCode := 16#8010;
            END_IF;
        16#8010:
            IF NOT S_SafeControl THEN
                DiagCode := 16#8002;
            ELSIF NOT R_TRIGatProcessControl.Q AND ProcessControl AND NOT StaticControl THEN
                DiagCode := 16#C010;
            ELSIF S_SafeControl AND (R_TRIGatProcessControl.Q OR (StaticControl AND ProcessControl)) THEN
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
        S_OutControl := FALSE;
        Error := FALSE;
    16#8000:
        Ready := TRUE;
        S_OutControl := TRUE;
        Error := FALSE;
    16#8001, 16#8002, 16#8003, 16#8010:
        Ready := TRUE;
        S_OutControl := FALSE;
        Error := FALSE;
    16#C001, 16#C002, 16#C010, 16#C111, 16#C211:
        Ready := TRUE;
        S_OutControl := FALSE;
        Error := TRUE;
END_CASE;

END_FUNCTION_BLOCK
FUNCTION_BLOCK SF_EnableSwitch2
VAR_INPUT
	Activate          : BOOL := FALSE;
	S_SafetyActive    : SAFEBOOL := FALSE;
	S_EnableSwitchCh1 : SAFEBOOL := FALSE;
	S_EnableSwitchCh2 : SAFEBOOL := FALSE;
	S_AutoReset       : SAFEBOOL := FALSE;
	Reset             : BOOL := FALSE;
END_VAR

VAR_OUTPUT
	Ready: BOOL := FALSE;
	S_EnableSwitchOut: SAFEBOOL := FALSE;
	Error: BOOL := FALSE;
	DiagCode: WORD := 16#0000;
END_VAR

VAR
	R_TRIGatReset: R_TRIG;
END_VAR

R_TRIGatReset(CLK:=Reset);

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSIF NOT S_SafetyActive THEN
    DiagCode := 16#8004;
ELSE

CASE DiagCode OF
16#0000:
    IF Activate THEN
	DiagCode := 16#8004;
    END_IF;
	
16#8000:
	IF (NOT (S_EnableSwitchCh1 OR S_EnableSwitchCh2)) OR (S_EnableSwitchCh1 AND NOT S_EnableSwitchCh2) THEN
		DiagCode := 16#8007;
	ELSIF NOT S_EnableSwitchCh1 AND S_EnableSwitchCh2 THEN
		DiagCode := 16#8006;
	END_IF;
	
16#8004:
    IF S_SafetyActive THEN
		DiagCode := 16#8005;
	END_IF;

16#8005:
	IF NOT (NOT S_EnableSwitchCh1 AND S_EnableSwitchCh2) THEN
		DiagCode := 16#C010;
	ELSIF NOT S_EnableSwitchCh1 AND S_EnableSwitchCh2 THEN
		DiagCode := 16#8006;
	END_IF;
	
16#8006:
	IF S_EnableSwitchCh1 AND S_EnableSwitchCh2 THEN
		DiagCode := 16#8000;
	ELSIF (NOT (S_EnableSwitchCh1 OR S_EnableSwitchCh2)) OR (S_EnableSwitchCh1 AND NOT S_EnableSwitchCh2) THEN
		DiagCode := 16#8007;
	END_IF;
	
16#8007:
	IF S_EnableSwitchCh1 AND S_EnableSwitchCh2 THEN
		DiagCode := 16#C030;
	ELSIF NOT S_EnableSwitchCh1 AND S_EnableSwitchCh2 THEN
		DiagCode := 16#8006;
	END_IF;
16#C001:
	IF NOT Reset THEN
		DiagCode := 16#C020;
	END_IF;
16#C002:
	IF NOT Reset THEN
		DiagCode := 16#C040;
	END_IF;
16#C010:
	IF NOT S_EnableSwitchCh1 AND S_EnableSwitchCh2 THEN
		DiagCode := 16#C020;
	END_IF;

16#C020:
	IF NOT (NOT S_EnableSwitchCh1 AND S_EnableSwitchCh2) THEN
		DiagCode := 16#C010;
	ELSIF Reset AND NOT R_TRIGatReset.Q AND NOT S_AutoReset THEN
		DiagCode := 16#C001;
	ELSIF R_TRIGatReset.Q OR S_AutoReset THEN
		DiagCode := 16#8006;
	END_IF;

16#C030:
	IF NOT (S_EnableSwitchCh1 AND S_EnableSwitchCh2) THEN
		DiagCode := 16#C040;
	END_IF;
	
16#C040:
	IF S_EnableSwitchCh1 AND S_EnableSwitchCh2 THEN
		DiagCode := 16#C030;
	ELSIF Reset AND R_TRIGatReset.Q AND NOT S_AutoReset THEN
		DiagCode := 16#C002;
	ELSIF R_TRIGatReset.Q OR S_AutoReset THEN
		DiagCode := 16#8007;
	END_IF;
END_CASE;

END_IF;

CASE DiagCode OF
16#C001,
16#C002,
16#C010,
16#C020,
16#C030,
16#C040:
	Ready := TRUE; 
	S_EnableSwitchOut := FALSE;
	Error := TRUE;
16#0000:
	Ready := FALSE; 
	S_EnableSwitchOut := FALSE; 
	Error := FALSE;
16#8000:
	Ready := TRUE; 
	S_EnableSwitchOut := TRUE;
	Error := FALSE;
	
16#8004,
16#8005,
16#8006,
16#8007:
	Ready := TRUE;
	S_EnableSwitchOut := FALSE;
	Error := FALSE;

END_CASE;

END_FUNCTION_BLOCK

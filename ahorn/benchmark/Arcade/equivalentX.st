FUNCTION_BLOCK equivalentX
VAR_INPUT
	Activate		: BOOL;
	S_ChannelA		: BOOL;
	S_ChannelB		: BOOL;
	DiscrepancyTime 	: TIME;
END_VAR
VAR_OUTPUT
	Ready		: BOOL;
	S_EquivalentOut	: BOOL;
	Error		: BOOL;
	DiagCode	: WORD;
END_VAR
VAR
 DiscrepancyTimer	: TONX;
END_VAR

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE

CASE DiagCode OF
16#0000:
    IF Activate THEN
	DiagCode := 16#8001;
    END_IF;
16#8001:
    IF S_ChannelA AND NOT S_ChannelB THEN
	DiagCode := 16#8004;
    ELSIF S_ChannelB AND NOT S_ChannelA THEN
	DiagCode := 16#8014;
    ELSIF S_ChannelA AND S_ChannelB THEN
	DiagCode := 16#8000;
    END_IF;
16#8004:
    IF DiscrepancyTimer.Q THEN
	DiagCode := 16#C001;
    ELSIF NOT S_ChannelA THEN
	DiagCode := 16#8001;
    ELSIF S_ChannelB THEN
	DiagCode := 16#8000;
    END_IF;
16#C001,
16#C002:
    IF NOT S_ChannelA AND NOT S_ChannelB THEN
	DiagCode := 16#8001;
    END_IF;
16#8014:
    IF DiscrepancyTimer.Q THEN
	DiagCode := 16#C002;
    ELSIF NOT S_ChannelB THEN
	DiagCode := 16#8001;
    ELSIF S_ChannelA THEN
	DiagCode := 16#8000;
    END_IF;
16#C003:
    IF NOT S_ChannelA AND NOT S_ChannelB THEN
	DiagCode := 16#8001;
    END_IF;
16#8005:
    IF DiscrepancyTimer.Q THEN
	DiagCode := 16#C003;
    ELSIF NOT S_ChannelA AND NOT S_ChannelB THEN
	DiagCode := 16#8001;
    END_IF;
16#8000:
    IF S_ChannelA XOR S_ChannelB THEN
	DiagCode := 16#8005;
    ELSIF NOT S_ChannelA AND NOT S_ChannelB THEN
	DiagCode := 16#8001;
    END_IF;
END_CASE;

END_IF;

CASE DiagCode OF
16#0000:
    DiscrepancyTimer(IN:=0, PT:=DiscrepancyTime);
    Ready := FALSE;
    Error := FALSE;
    S_EquivalentOut:= FALSE;
16#8000:
    DiscrepancyTimer(IN:=0, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := FALSE;
    S_EquivalentOut := TRUE;
16#8001:
    DiscrepancyTimer(IN:=0, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := FALSE;
    S_EquivalentOut:= FALSE;
16#8004,
16#8014,
16#8005:
	DiscrepancyTimer(IN:=1, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := FALSE;
    S_EquivalentOut:= FALSE;
16#C001,
16#C002,
16#C003:
    DiscrepancyTimer(IN:=0, PT:=DiscrepancyTime);
    Ready := TRUE;
    Error := TRUE;
    S_EquivalentOut:= FALSE;
END_CASE;

END_FUNCTION_BLOCK
FUNCTION_BLOCK SF_Mode_Selector
VAR_INPUT
        Activate        : BOOL;
        S_Mode0         : BOOL;
        S_Mode1         : BOOL;
        S_Mode2         : BOOL;
        S_Mode3         : BOOL;
        S_Mode4         : BOOL;
        S_Mode5         : BOOL;
        S_Mode6         : BOOL;
        S_Mode7         : BOOL;
        S_Unlock        : BOOL;
        S_SetMode       : BOOL;
        AutoSetMode     : BOOL;
        ModeMonitorTime : TIME; 
        Reset           : BOOL;
 END_VAR
 VAR_OUTPUT
        Ready           : BOOL;
        S_Mode0Sel      : BOOL;
        S_Mode1Sel      : BOOL;
        S_Mode2Sel      : BOOL;
        S_Mode3Sel      : BOOL;
        S_Mode4Sel      : BOOL;
        S_Mode5Sel      : BOOL;
        S_Mode6Sel      : BOOL;
        S_Mode7Sel      : BOOL;
        S_AnyModeSel    : BOOL;
        Error           : BOOL;
        DiagCode        : WORD;
 END_VAR
 VAR
        T_1        : TON;                 (* Timer for S2, transition T27 *)
 END_VAR

 VAR
        R_TRIGatReset: R_TRIG;
        R_TRIGatSetMode: R_TRIG;
        F_TRIGatModeSel0: F_TRIG;
        R_TRIGatModeSel0: R_TRIG;
 END_VAR

 VAR_TEMP
    Error1 : BOOL;
    Error2 : BOOL;
 END_VAR
 
R_TRIGatReset(CLK:=Reset);
R_TRIGatSetMode(CLK:=S_SetMode);

IF NOT Activate THEN
    DiagCode := 16#0000;
END_IF;

IF (S_Mode0 + S_Mode1 + S_Mode2 + S_Mode3 + S_Mode4 + S_Mode5 + S_Mode6 + S_Mode7 > 1) THEN
    Error1 := true;
ELSE
    Error1 := false;
END_IF;

CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8005;
    END_IF;
16#8005:
    IF (NOT S_Mode0 AND NOT S_Mode1 AND NOT S_Mode2 AND NOT S_Mode3 AND NOT S_Mode4 AND NOT S_Mode5 AND NOT S_Mode6 AND NOT S_Mode7) THEN
        F_TRIGatModeSel0(CLK:=true);
        R_TRIGatModeSel0(CLK:=true);
    ELSE
        F_TRIGatModeSel0(CLK:=false);
        R_TRIGatModeSel0(CLK:=false);
    END_IF;

    IF F_TRIGatModeSel0.Q THEN
        T_1(IN:=true, PT:=ModeMonitorTime);
    ELSIF R_TRIGatModeSel0.Q THEN
        T_1(IN:=false, PT:=ModeMonitorTime);
    END_IF;

    Error2 := T_1.Q;

    IF Error1 THEN
        DiagCode := 16#C001;
    ELSIF Error2 THEN
        DiagCode := 16#C002;
    ELSIF ((AutoSetMode OR R_TRIGatSetMode.Q) AND S_Unlock AND (S_Mode0 + S_Mode1 + S_Mode2 + S_Mode3 + S_Mode4 + S_Mode5 + S_Mode6 + S_Mode7 = 1)) THEN
        DiagCode := 16#8000;
    END_IF;
16#8000:
    IF Error1 THEN
        DiagCode := 16#C001;
    ELSIF (S_Mode0 <> S_Mode0Sel OR S_Mode1 <> S_Mode1Sel OR S_Mode2 <> S_Mode2Sel OR S_Mode3 <> S_Mode3Sel
          OR S_Mode4 <> S_Mode4Sel OR S_Mode5 <> S_Mode5Sel OR S_Mode6 <> S_Mode6Sel OR S_Mode7 <> S_Mode7Sel) THEN
        DiagCode := 16#8005;
    ELSIF (NOT S_Unlock) THEN
        DiagCode := 16#8004;
    END_IF;
16#8004:
    IF S_Unlock THEN
        DiagCode := 16#8000;
    END_IF;
16#C001:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C003;
    ELSIF R_TRIGatReset.Q THEN
        DiagCode := 16#8005;
    END_IF;
16#C002:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C004;
    ELSIF R_TRIGatReset.Q THEN
        DiagCode := 16#8005;
    END_IF;
16#C003:
    IF (NOT Reset) THEN
                DiagCode := 16#C001;
    END_IF;
16#C004:
    IF (NOT Reset) THEN
                DiagCode := 16#C002;
    END_IF;
END_CASE;

CASE DiagCode OF
16#0000:
    Ready := false;
    S_Mode0Sel := false;
    S_Mode1Sel := false;
    S_Mode2Sel := false;
    S_Mode3Sel := false;
    S_Mode4Sel := false;
    S_Mode5Sel := false;
    S_Mode6Sel := false;
    S_Mode7Sel := false;
    S_AnyModeSel := false;
    Error := false;
16#8005:
    Ready := true;
    S_Mode0Sel := false;
    S_Mode1Sel := false;
    S_Mode2Sel := false;
    S_Mode3Sel := false;
    S_Mode4Sel := false;
    S_Mode5Sel := false;
    S_Mode6Sel := false;
    S_Mode7Sel := false;
    S_AnyModeSel := false;
    Error := false;
16#8000:
    Ready := true;
    S_Mode0Sel := S_Mode0;
    S_Mode1Sel := S_Mode1;
    S_Mode2Sel := S_Mode2;
    S_Mode3Sel := S_Mode3;
    S_Mode4Sel := S_Mode4;
    S_Mode5Sel := S_Mode5;
    S_Mode6Sel := S_Mode6;
    S_Mode7Sel := S_Mode7;
    S_AnyModeSel := true;
    Error := false;
16#8004:
    Ready := true;
    S_AnyModeSel := true;
    Error := false;
16#C001,
16#C002,
16#C003,
16#C004:
    Ready := true;
    S_Mode0Sel := false;
    S_Mode1Sel := false;
    S_Mode2Sel := false;
    S_Mode3Sel := false;
    S_Mode4Sel := false;
    S_Mode5Sel := false;
    S_Mode6Sel := false;
    S_Mode7Sel := false;
    S_AnyModeSel := false;
    Error := true;
END_CASE;

IF (DiagCode <> 16#8005) THEN
    T_1(IN:=false, PT:=ModeMonitorTime);
END_IF;
END_FUNCTION_BLOCK
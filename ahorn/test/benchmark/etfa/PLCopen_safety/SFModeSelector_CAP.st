PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SMode0 : BOOL;
    SMode1 : BOOL;
    SMode2 : BOOL;
    SMode3 : BOOL;
    SMode4 : BOOL;
    SMode5 : BOOL;
    SMode6 : BOOL;
    SMode7 : BOOL;
    SUnlock : BOOL;
    SSetMode : BOOL;
    AutoSetMode : BOOL;
    ModeMonitorTime : TIME;
    Reset : BOOL;
END_VAR
VAR
    SFModeSelector : SFModeSelector;
END_VAR
SFModeSelector(Activate:=Activate,SMode0:=SMode0,SMode1:=SMode1,SMode2:=SMode2,SMode3:=SMode3,SMode4:=SMode4,SMode5:=SMode5,
SMode6:=SMode6,SMode7:=SMode7,SUnlock:=SUnlock,SSetMode:=SSetMode,AutoSetMode:=AutoSetMode,ModeMonitorTime:=ModeMonitorTime,
Reset:=Reset);
END_PROGRAM

FUNCTION_BLOCK SFModeSelector
VAR_INPUT
    Activate : BOOL;
    SMode0 : BOOL;
    SMode1 : BOOL;
    SMode2 : BOOL;
    SMode3 : BOOL;
    SMode4 : BOOL;
    SMode5 : BOOL;
    SMode6 : BOOL;
    SMode7 : BOOL;
    SUnlock : BOOL;
    SSetMode : BOOL;
    AutoSetMode : BOOL;
    ModeMonitorTime : TIME;
    Reset : BOOL;
END_VAR
VAR
    IN : BOOL;
    PT : TIME;
    running : BOOL;
    Q : BOOL;
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
    RTRIGatSetModeQ : BOOL;
    RTRIGatSetModeM : BOOL;
    FTRIGatModeSel0Q : BOOL;
    FTRIGatModeSel0M : BOOL;
    RTRIGatModeSel0Q: BOOL;
    RTRIGatModeSel0M: BOOL;
    fallingEdgeDetected : BOOL;
END_VAR
VAR_TEMP
    Error1 : BOOL;
    Error2 : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL;
    SMode0Sel : BOOL;
    SMode1Sel : BOOL;
    SMode2Sel : BOOL;
    SMode3Sel : BOOL;
    SMode4Sel : BOOL;
    SMode5Sel : BOOL;
    SMode6Sel : BOOL;
    SMode7Sel : BOOL;
    SAnyModeSel : BOOL;
    Error : BOOL;
    DiagCode : WORD;
END_VAR
RTRIGatResetQ := Reset AND NOT RTRIGatResetM;
RTRIGatResetM := Reset;

RTRIGatSetModeQ := SSetMode AND NOT RTRIGatSetModeM;
RTRIGatSetModeM := SSetMode;

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    IF (SMode0 + SMode1 + SMode2 + SMode3 + SMode4 + SMode5 + SMode6 + SMode7 > 1) THEN
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
        IF (NOT SMode0 AND NOT SMode1 AND NOT SMode2 AND NOT SMode3 AND NOT SMode4 AND NOT SMode5 AND NOT SMode6 AND NOT SMode7) THEN
            FTRIGatModeSel0Q := NOT false AND FTRIGatModeSel0M;
            FTRIGatModeSel0M := false;
            RTRIGatModeSel0Q := false AND NOT RTRIGatModeSel0M;
            RTRIGatModeSel0M := false;
        ELSE
            FTRIGatModeSel0Q := NOT true AND FTRIGatModeSel0M;
            FTRIGatModeSel0M := true;
            RTRIGatModeSel0Q := true AND NOT RTRIGatModeSel0M;
            RTRIGatModeSel0M := true;
        END_IF;
        IF FTRIGatModeSel0Q THEN
            fallingEdgeDetected := TRUE;
        END_IF;
        IF fallingEdgeDetected THEN
            IN:=TRUE;
            PT:=ModeMonitorTime;
            IF NOT running AND NOT Q THEN
                running := TRUE;
            ELSIF running AND NOT Q THEN
                Q := NONDETERMINISTIC_BOOL();
                running := NOT Q;
            END_IF;
        ELSIF RTRIGatModeSel0Q THEN
            IN:=FALSE;
            PT:=ModeMonitorTime;
            Q := FALSE;
            running := FALSE;
            fallingEdgeDetected := FALSE;
        END_IF;
        Error2 := Q;
        IF Error1 THEN
            DiagCode := 16#C001;
        ELSIF Error2 THEN
            DiagCode := 16#C002;
        ELSIF ((AutoSetMode OR RTRIGatSetModeQ) AND SUnlock AND (SMode0 + SMode1 + SMode2 + SMode3 + SMode4 + SMode5 + SMode6 + SMode7 = 1)) THEN
            DiagCode := 16#8000;
        END_IF;
    16#8000:
        IF Error1 THEN
            DiagCode := 16#C001;
        ELSIF (SMode0 <> SMode0Sel OR SMode1 <> SMode1Sel OR SMode2 <> SMode2Sel OR SMode3 <> SMode3Sel
              OR SMode4 <> SMode4Sel OR SMode5 <> SMode5Sel OR SMode6 <> SMode6Sel OR SMode7 <> SMode7Sel) THEN
            DiagCode := 16#8005;
            fallingEdgeDetected := FALSE;
        ELSIF (NOT SUnlock) THEN
            DiagCode := change(16#8004, 16#8000);
        END_IF;
    16#8004:
        IF SUnlock THEN
            DiagCode := 16#8000;
        END_IF;
    16#C001:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C003;
        ELSIF RTRIGatResetQ THEN
            DiagCode := 16#8005;
            fallingEdgeDetected := FALSE;
        END_IF;
    16#C002:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C004;
        ELSIF RTRIGatResetQ THEN
            DiagCode := 16#8005;
            fallingEdgeDetected := FALSE;
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
END_IF;

CASE DiagCode OF
16#0000:
    Ready := false;
    SMode0Sel := false;
    SMode1Sel := false;
    SMode2Sel := false;
    SMode3Sel := false;
    SMode4Sel := false;
    SMode5Sel := false;
    SMode6Sel := false;
    SMode7Sel := false;
    SAnyModeSel := false;
    Error := false;
16#8005:
    Ready := true;
    SMode0Sel := false;
    SMode1Sel := false;
    SMode2Sel := false;
    SMode3Sel := false;
    SMode4Sel := false;
    SMode5Sel := false;
    SMode6Sel := false;
    SMode7Sel := false;
    SAnyModeSel := false;
    Error := false;
16#8000:
    Ready := true;
    SMode0Sel := SMode0;
    SMode1Sel := SMode1;
    SMode2Sel := SMode2;
    SMode3Sel := SMode3;
    SMode4Sel := SMode4;
    SMode5Sel := SMode5;
    SMode6Sel := SMode6;
    SMode7Sel := SMode7;
    SAnyModeSel := true;
    Error := false;
16#8004:
    Ready := true;
    SAnyModeSel := true;
    Error := false;
16#C001,
16#C002,
16#C003,
16#C004:
    Ready := true;
    SMode0Sel := false;
    SMode1Sel := false;
    SMode2Sel := false;
    SMode3Sel := false;
    SMode4Sel := false;
    SMode5Sel := false;
    SMode6Sel := false;
    SMode7Sel := false;
    SAnyModeSel := false;
    Error := true;
END_CASE;
IF (DiagCode <> 16#8005) THEN
    IN:=FALSE;
    PT:=ModeMonitorTime;
    Q := FALSE;
    running := FALSE;
END_IF;
END_FUNCTION_BLOCK
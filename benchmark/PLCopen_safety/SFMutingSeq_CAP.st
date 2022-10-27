PROGRAM Main
VAR_INPUT
    Activate : BOOL := FALSE;
    SAOPDIn : SAFEBOOL := FALSE;
    MutingSwitch11 : BOOL := FALSE;
    MutingSwitch12 : BOOL := FALSE;
    MutingSwitch21 : BOOL := FALSE;
    MutingSwitch22 : BOOL := FALSE;
    SMutingLamp : SAFEBOOL := FALSE;
    DiscTime1112 : TIME := T#0s;
    DiscTime2122 : TIME := T#0s;
    MaxMutingTime : TIME := T#0s;
    MutingEnable : BOOL := FALSE;
    SStartReset : SAFEBOOL := FALSE;
    Reset : BOOL := FALSE;
END_VAR
VAR
    SFMutingSeq : SFMutingSeq;
END_VAR
SFMutingSeq(Activate:=Activate,SAOPDIn:=SAOPDIn,MutingSwitch11:=MutingSwitch11,MutingSwitch12:=MutingSwitch12,MutingSwitch21:=MutingSwitch21,
MutingSwitch22:=MutingSwitch22,SMutingLamp:=SMutingLamp,DiscTime1112:=DiscTime1112,DiscTime2122:=DiscTime2122,
MaxMutingTime:=MaxMutingTime,MutingEnable:=MutingEnable,SStartReset:=SStartReset,Reset:=Reset);
END_PROGRAM

FUNCTION_BLOCK SFMutingSeq
VAR_INPUT
    Activate : BOOL := FALSE;
    SAOPDIn : SAFEBOOL := FALSE;
    MutingSwitch11 : BOOL := FALSE;
    MutingSwitch12 : BOOL := FALSE;
    MutingSwitch21 : BOOL := FALSE;
    MutingSwitch22 : BOOL := FALSE;
    SMutingLamp : SAFEBOOL := FALSE;
    DiscTime1112 : TIME := T#0s;
    DiscTime2122 : TIME := T#0s;
    MaxMutingTime : TIME := T#0s;
    MutingEnable : BOOL := FALSE;
    SStartReset : SAFEBOOL := FALSE;
    Reset : BOOL := FALSE;
END_VAR
VAR
    IN : BOOL;
    PT : TIME;
    running : BOOL;
    Q : BOOL;
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
    RTRIGatMS11Q : BOOL;
    RTRIGatMS11M : BOOL;
    RTRIGatMS12Q : BOOL;
    RTRIGatMS12M : BOOL;
    RTRIGatMS21Q : BOOL;
    RTRIGatMS21M : BOOL;
    RTRIGatMS22Q : BOOL;
    RTRIGatMS22M : BOOL;
    FTRIGatMS11Q : BOOL;
    FTRIGatMS11M : BOOL;
    FTRIGatMS12Q : BOOL;
    FTRIGatMS12M : BOOL;
    FTRIGatMS21Q : BOOL;
    FTRIGatMS21M : BOOL;
    FTRIGatMS22Q : BOOL;
    FTRIGatMS22M : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL := FALSE;
    SAOPDOut : SAFEBOOL := FALSE;
    SMutingActive : SAFEBOOL := FALSE;
    Error : BOOL := FALSE;
    DiagCode : WORD := 16#0000;
END_VAR
RTRIGatResetQ := Reset AND NOT RTRIGatResetM;
RTRIGatResetM := Reset;

RTRIGatMS11Q := MutingSwitch11 AND NOT RTRIGatMS11M;
RTRIGatMS11M := MutingSwitch11;

RTRIGatMS12Q := MutingSwitch12 AND NOT RTRIGatMS12M;
RTRIGatMS12M := MutingSwitch12;

RTRIGatMS21Q := MutingSwitch21 AND NOT RTRIGatMS21M;
RTRIGatMS21M := MutingSwitch21;

RTRIGatMS22Q := MutingSwitch22 AND NOT RTRIGatMS22M;
RTRIGatMS22M := MutingSwitch22;

FTRIGatMS11Q := NOT MutingSwitch11 AND FTRIGatMS11M;
FTRIGatMS11M := MutingSwitch11;

FTRIGatMS12Q := NOT MutingSwitch12 AND FTRIGatMS12M;
FTRIGatMS12M := MutingSwitch12;

FTRIGatMS21Q := NOT MutingSwitch21 AND FTRIGatMS21M;
FTRIGatMS21M := MutingSwitch21;

FTRIGatMS22Q := NOT MutingSwitch22 AND FTRIGatMS22M;
FTRIGatMS22M := MutingSwitch22;

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
    16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
    16#8000:
        IF (NOT MutingEnable AND RTRIGatMS11Q) OR (NOT MutingEnable AND RTRIGatMS22Q) OR (MutingSwitch12 OR MutingSwitch21) OR (MutingSwitch11 AND MutingSwitch22) THEN
            (* Wrong muting sequence *)
            DiagCode := 16#C004;
        ELSIF NOT SAOPDIn THEN
            DiagCode := 16#8002;
        ELSIF NOT SMutingLamp THEN
            DiagCode := 16#C003;
        ELSIF MutingEnable AND (RTRIGatMS11Q AND NOT MutingSwitch12 AND NOT MutingSwitch21 AND NOT MutingSwitch22) THEN
            DiagCode := change(16#8011, 16#8005);
            IN:=TRUE;
            PT:=MaxMutingTime;
            IF NOT running AND NOT Q THEN
                running := TRUE;
            ELSIF running AND NOT Q THEN
                Q := NONDETERMINISTIC_BOOL();
                running := NOT Q;
            END_IF;
        ELSIF MutingEnable AND (NOT MutingSwitch11 AND NOT MutingSwitch12 AND NOT MutingSwitch21 AND RTRIGatMS22Q) THEN
            DiagCode := 16#8122;
            IN:=TRUE;
            PT:=MaxMutingTime;
            IF NOT running AND NOT Q THEN
                running := TRUE;
            ELSIF running AND NOT Q THEN
                Q := NONDETERMINISTIC_BOOL();
                running := NOT Q;
            END_IF;
        END_IF;
    16#8001:
        IF Reset AND NOT RTRIGatResetQ AND NOT SStartReset THEN
            DiagCode := 16#C001;
        (*
        ELSIF (Time parameters out of range)
        DiagCode := 16#C005;
        *)
        ELSIF RTRIGatResetQ OR SStartReset THEN
            DiagCode := 16#8005;
        END_IF;
    16#8002:
        IF SAOPDIn THEN
            DiagCode := 16#8003;
        END_IF;
    16#8003:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C002;
        ELSIF RTRIGatResetQ THEN
            DiagCode := 16#8005;
        END_IF;
    16#8005:
        IF NOT SAOPDIn THEN
            DiagCode := 16#8002;
        ELSIF NOT SMutingLamp THEN
            DiagCode := 16#C003;
        ELSIF SAOPDIn THEN
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
    16#C003:
        IF SMutingLamp THEN
            DiagCode := 16#8003;
        END_IF;
    16#C006,
    16#C007,
    16#C008:
        IF NOT (MutingSwitch11 OR MutingSwitch12 OR MutingSwitch21 OR MutingSwitch22) THEN
            DiagCode := 16#8003;
        END_IF;
    ELSE
        IF DiagCode >= 16#C000 THEN
        (* 16#CYx4 *)
            IF NOT (MutingSwitch11 OR MutingSwitch12 OR MutingSwitch21 OR MutingSwitch22) THEN
                DiagCode := 16#8003;
            END_IF;
        ELSE
            (* cases 16#8011 .. 16#8422 *)
            CASE DiagCode OF
            16#8011:
                IF NOT MutingEnable OR NOT MutingSwitch11 OR MutingSwitch21 OR MutingSwitch22 THEN
                    DiagCode := 16#C104;
                ELSIF Q THEN
                    DiagCode := 16#C006;
                ELSIF NOT SAOPDIn THEN
                    DiagCode := 16#8002;
                ELSIF NOT SMutingLamp THEN
                    DiagCode := 16#C003;
                ELSIF MutingEnable AND (MutingSwitch11 AND RTRIGatMS12Q AND NOT MutingSwitch21 AND NOT MutingSwitch22) THEN
                    DiagCode := 16#8012;
                END_IF;
            16#8012:
                IF RTRIGatMS11Q OR RTRIGatMS12Q OR FTRIGatMS22Q THEN
                    DiagCode := 16#C104;
                ELSIF Q THEN
                    DiagCode := 16#C006;
                ELSIF NOT SMutingLamp THEN
                    DiagCode := 16#C003;
                ELSIF NOT MutingSwitch11 AND NOT MutingSwitch12 AND FTRIGatMS21Q AND MutingSwitch22 THEN
                    IN:=FALSE;
                    PT:=MaxMutingTime;
                    Q := FALSE;
                    running := FALSE;
                    DiagCode := 16#8000;
                END_IF;
            16#8122:
                IF NOT MutingEnable OR MutingSwitch11 OR MutingSwitch12 OR NOT MutingSwitch22 THEN
                    DiagCode := 16#C104;
                ELSIF Q THEN
                    DiagCode := 16#C006;
                ELSIF NOT SAOPDIn THEN
                    DiagCode := 16#8002;
                ELSIF NOT SMutingLamp THEN
                    DiagCode := 16#C003;
                ELSIF MutingEnable AND (NOT MutingSwitch11 AND NOT MutingSwitch12 AND RTRIGatMS21Q AND MutingSwitch22) THEN
                    DiagCode := 16#8112;
                END_IF;
            16#8112:
                IF FTRIGatMS11Q OR RTRIGatMS21Q OR RTRIGatMS22Q THEN
                    DiagCode := 16#C104;
                ELSIF Q THEN
                    DiagCode := 16#C006;
                ELSIF NOT SMutingLamp THEN
                    DiagCode := 16#C003;
                ELSIF MutingSwitch11 AND FTRIGatMS12Q AND NOT MutingSwitch21 AND NOT MutingSwitch22 THEN
                    DiagCode := 16#8000;
                    IN:=FALSE;
                    PT:=MaxMutingTime;
                    Q := FALSE;
                    running := FALSE;
                END_IF;
            END_CASE;
        END_IF;
    END_CASE;
END_IF;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    SAOPDOut := FALSE;
    SMutingActive := FALSE;
    Error := FALSE;
16#8000,
16#8011,
16#8122:
    Ready := TRUE;
    SAOPDOut := TRUE;
    SMutingActive := FALSE;
    Error := FALSE;
16#8001,
16#8002,
16#8003,
16#8005:
    Ready := TRUE;
    SAOPDOut := FALSE;
    SMutingActive := FALSE;
    Error := FALSE;
16#8012,
16#8112:
    Ready := TRUE;
    SAOPDOut := TRUE;
    SMutingActive := TRUE;
    Error := FALSE;
ELSE
    Ready := TRUE;
    SAOPDOut := FALSE;
    SMutingActive := FALSE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK

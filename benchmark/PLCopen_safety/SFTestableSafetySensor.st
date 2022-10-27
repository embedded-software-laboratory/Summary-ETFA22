PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SOSSDIn : SAFEBOOL;
    StartTest : BOOL;
    TestTime : TIME := T#10ms;
    NoExternalTest : BOOL;
    SStartReset : SAFEBOOL;
    SAutoReset : SAFEBOOL;
    Reset : BOOL;
END_VAR
VAR
    SFTestableSafetySensor : SFTestableSafetySensor;
END_VAR
SFTestableSafetySensor(Activate:=Activate,SOSSDIn:=SOSSDIn,StartTest:=StartTest,TestTime:=TestTime,NoExternalTest:=NoExternalTest,
SStartReset:=SStartReset,SAutoReset:=SAutoReset,Reset:=Reset);
END_PROGRAM

FUNCTION_BLOCK SFTestableSafetySensor
VAR_INPUT
    Activate : BOOL;
    SOSSDIn : SAFEBOOL;
    StartTest : BOOL;
    TestTime : TIME := T#10ms;
    NoExternalTest : BOOL;
    SStartReset : SAFEBOOL;
    SAutoReset : SAFEBOOL;
    Reset : BOOL;
END_VAR
VAR
    IN1 : BOOL;
    PT1 : TIME;
    running1 : BOOL;
    Q1 : BOOL;
    IN2 : BOOL;
    PT2 : TIME;
    running2 : BOOL;
    Q2 : BOOL;
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
    RTRIGatStartTestQ : BOOL;
    RTRIGatStartTestM : BOOL;
    FTRIGatSOSSDInQ : BOOL;
    FTRIGatSOSSDInM : BOOL;
END_VAR
VAR_OUTPUT
    Ready : SAFEBOOL;
    SOSSDOut : SAFEBOOL;
    STestOut : SAFEBOOL := TRUE;
    TestPossible : BOOL;
    TestExecuted : BOOL;
    Error : BOOL;
    DiagCode : WORD := 16#0000;
END_VAR
RTRIGatResetQ := Reset AND NOT RTRIGatResetM;
RTRIGatResetM := Reset;

RTRIGatStartTestQ := StartTest AND NOT RTRIGatStartTestM;
RTRIGatStartTestM := StartTest;

FTRIGatSOSSDInQ := NOT SOSSDIn AND FTRIGatSOSSDInM;
FTRIGatSOSSDInM := SOSSDIn;

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
    16#0000:
        IF Activate THEN
            DiagCode := 16#8001;
        END_IF;
    16#8000:
        IF NOT SOSSDIn THEN
            DiagCode := 16#8012;
        ELSIF RTRIGatStartTestQ THEN
            DiagCode := 16#8020;
            IN1:=FALSE;
            Q1 := FALSE;
            running1 := FALSE;
        END_IF;
    16#8001:
        IF TestTime > T#150ms THEN
            DiagCode := 16#C000;
        ELSIF Reset AND NOT RTRIGatResetQ AND NOT SStartReset THEN
            DiagCode := 16#C001;
        ELSIF NOT SOSSDIn THEN
            DiagCode := 16#8002;
        ELSIF SOSSDIn AND (RTRIGatResetQ OR SStartReset) THEN
            DiagCode := 16#8010;
        END_IF;
    16#8002:
        IF SOSSDIn THEN
            DiagCode := 16#8003;
        END_IF;
    16#8003:
        IF Reset AND NOT RTRIGatResetQ AND NOT SAutoReset THEN
            DiagCode := 16#C002;
        ELSIF NOT SOSSDIn THEN
            DiagCode := 16#8002;
        ELSIF SOSSDIn AND (RTRIGatResetQ OR SAutoReset) THEN
            DiagCode := 16#8010;
        END_IF;
    16#8004:
        IF FTRIGatSOSSDInQ THEN
            DiagCode := 16#8005;
        END_IF;
    16#8005:
        IF SOSSDIn THEN
            DiagCode := 16#8006;
        END_IF;
    16#8006:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C005;
        ELSIF RTRIGatResetQ AND NOT SOSSDIn THEN
            DiagCode := 16#8002;
        ELSIF RTRIGatResetQ AND SOSSDIn THEN
            DiagCode := 16#8010;
        END_IF;
    16#8010:
        IF NOT SOSSDIn THEN
            DiagCode := 16#8002;
        ELSIF RTRIGatStartTestQ THEN
            DiagCode := 16#8020;
            IN1:=FALSE;
            Q1 := FALSE;
            running1 := FALSE;
        END_IF;
    16#8012:
        IF SOSSDIn THEN
            DiagCode := 16#8013;
        END_IF;
    16#8013:
        IF Reset AND NOT RTRIGatResetQ AND NOT SAutoReset THEN
            DiagCode := 16#C007;
        ELSIF NOT SOSSDIn THEN
            DiagCode := 16#8012;
        ELSIF SOSSDIn AND (RTRIGatResetQ OR SAutoReset) THEN
            DiagCode := 16#8000;
        END_IF;
    16#8020:
        IF Q1 THEN
            DiagCode := 16#C020;
        ELSIF NOT SOSSDIn THEN
            DiagCode := 16#8030;
            IN2:=FALSE;
            Q2 := FALSE;
            running2 := FALSE;
        END_IF;
    16#8030:
        IF Q2 THEN
            DiagCode := 16#C030;
        ELSIF SOSSDIn THEN
            DiagCode := 16#8000;
        END_IF;
    16#C000:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C006;
        ELSIF RTRIGatResetQ AND TestTime <= T#150ms THEN
            DiagCode := 16#8001;
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
        IF NOT Reset THEN
            DiagCode := 16#C010;
        END_IF;
    16#C004:
        IF NOT Reset THEN
            DiagCode := 16#C020;
        END_IF;
    16#C005:
        IF NOT Reset THEN
            DiagCode := 16#8006;
        END_IF;
    16#C006:
        IF NOT Reset THEN
            DiagCode := 16#C000;
        END_IF;
    16#C007:
        IF NOT Reset THEN
            DiagCode := 16#8013;
        END_IF;
    16#C010:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C003;
        ELSIF RTRIGatResetQ AND NOT NoExternalTest THEN
            DiagCode := 16#8004;
        ELSIF SOSSDIn AND (RTRIGatResetQ AND NoExternalTest) THEN
            DiagCode := 16#8010;
        END_IF;
    16#C020:
        IF Reset AND NOT RTRIGatResetQ THEN
            DiagCode := 16#C004;
        ELSIF RTRIGatResetQ AND NOT NoExternalTest THEN
            DiagCode := 16#8004;
        ELSIF SOSSDIn AND (RTRIGatResetQ AND NoExternalTest) THEN
            DiagCode := 16#8010;
        END_IF;
    END_CASE;
END_IF;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    SOSSDOut := FALSE;
    STestOut := TRUE;
    TestPossible := FALSE;
    TestExecuted := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    SOSSDOut := TRUE;
    STestOut := TRUE;
    TestPossible := TRUE;
    TestExecuted := TRUE;
    Error := FALSE;
16#8001, 16#8002, 16#8003, 16#8004, 16#8005, 16#8006:
    Ready := TRUE;
    SOSSDOut := FALSE;
    STestOut := TRUE;
    TestPossible := FALSE;
    TestExecuted := FALSE;
    Error := FALSE;
16#8010:
    Ready := TRUE;
    SOSSDOut := TRUE;
    STestOut := TRUE;
    TestPossible := TRUE;
    TestExecuted := FALSE;
    Error := FALSE;
16#8012, 16#8013:
    Ready := TRUE;
    SOSSDOut := FALSE;
    STestOut := TRUE;
    TestPossible := FALSE;
    TestExecuted := TRUE;
    Error := FALSE;
16#8020:
    Ready := TRUE;
    SOSSDOut := TRUE;
    STestOut := FALSE;
    TestPossible := FALSE;
    TestExecuted := FALSE;
    Error := FALSE;
    IN1:=TRUE;
    PT1:=TestTime;
    IF NOT running1 AND NOT Q1 THEN
        running1 := TRUE;
    ELSIF running1 AND NOT Q1 THEN
        Q1 := NONDETERMINISTIC_BOOL();
        running1 := NOT Q1;
    END_IF;
16#8030:
    Ready := TRUE;
    SOSSDOut := TRUE;
    STestOut := TRUE;
    TestPossible := FALSE;
    TestExecuted := FALSE;
    Error := FALSE;
    IN2:=TRUE;
    PT2:=TestTime;
    IF NOT running2 AND NOT Q2 THEN
        running2 := TRUE;
    ELSIF running2 AND NOT Q2 THEN
        Q2 := NONDETERMINISTIC_BOOL();
        running2 := NOT Q2;
    END_IF;
16#C000, 16#C001, 16#C002, 16#C003, 16#C004, 16#C005, 16#C006, 16#C010, 16#C020:
    Ready := TRUE;
    SOSSDOut := FALSE;
    STestOut := TRUE;
    TestPossible := FALSE;
    TestExecuted := FALSE;
    Error := TRUE;
16#C007:
    Ready := TRUE;
    SOSSDOut := FALSE;
    STestOut := TRUE;
    TestPossible := FALSE;
    TestExecuted := TRUE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK
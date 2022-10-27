FUNCTION_BLOCK SF_Testable_Safety_Sensor
VAR_INPUT
    Activate : BOOL;
    S_OSSD_In : SAFEBOOL;
    StartTest : BOOL;
    TestTime : TIME := T#10ms;
    NoExternalTest : BOOL;
    S_StartReset : SAFEBOOL;
    S_AutoReset : SAFEBOOL;
    Reset : BOOL;
END_VAR
VAR_OUTPUT
    Ready : SAFEBOOL;
    S_OSSD_Out : SAFEBOOL;
    S_TestOut : SAFEBOOL := TRUE;
    TestPossible : BOOL;
    TestExecuted : BOOL;
    Error : BOOL;
    DiagCode : WORD := 16#0000;
END_VAR
VAR
    R_TRIGatReset : R_TRIG;
    R_TRIGatStartTest : R_TRIG;
    F_TRIGatS_OSSD_In : F_TRIG;
    Timer1: TON;
    Timer2: TON;
END_VAR

R_TRIGatReset(CLK:=Reset);
R_TRIGatStartTest(CLK:=StartTest);
F_TRIGatS_OSSD_In(CLK:=S_OSSD_In);

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE
    CASE DiagCode OF
        16#0000:
            IF Activate THEN
                DiagCode := 16#8001;
            END_IF;
        16#8000:
            IF NOT S_OSSD_In THEN
                DiagCode := 16#8012;
            ELSIF R_TRIGatStartTest.Q THEN
                DiagCode := 16#8020;
                Timer1(IN:=FALSE);
            END_IF;
        16#8001:
            IF TestTime > T#150ms THEN
                DiagCode := 16#C000;
            ELSIF Reset AND NOT R_TRIGatReset.Q AND NOT S_StartReset THEN
                DiagCode := 16#C001;
            ELSIF NOT S_OSSD_In THEN
                DiagCode := 16#8002;
            ELSIF S_OSSD_In AND (R_TRIGatReset.Q OR S_StartReset) THEN
                DiagCode := 16#8010;
            END_IF;
        16#8002:
            IF S_OSSD_In THEN
                DiagCode := 16#8003;
            END_IF;
        16#8003:
            IF Reset AND NOT R_TRIGatReset.Q AND NOT S_AutoReset THEN
                DiagCode := 16#C002;
            ELSIF NOT S_OSSD_In THEN
                DiagCode := 16#8002;
            ELSIF S_OSSD_In AND (R_TRIGatReset.Q OR S_AutoReset) THEN
                DiagCode := 16#8010;
            END_IF;
        16#8004:
            IF F_TRIGatS_OSSD_In.Q THEN
                DiagCode := 16#8005;
            END_IF;
        16#8005:
            IF S_OSSD_In THEN
                DiagCode := 16#8006;
            END_IF;
        16#8006:
            IF Reset AND NOT R_TRIGatReset.Q THEN
                DiagCode := 16#C005;
            ELSIF R_TRIGatReset.Q AND NOT S_OSSD_In THEN
                DiagCode := 16#8002;
            ELSIF R_TRIGatReset.Q AND S_OSSD_In THEN
                DiagCode := 16#8010;
            END_IF;
        16#8010:
            IF NOT S_OSSD_In THEN
                DiagCode := 16#8002;
            ELSIF R_TRIGatStartTest.Q THEN
                DiagCode := 16#8020;
                Timer1(IN:=FALSE);
            END_IF;
        16#8012:
            IF S_OSSD_In THEN
                DiagCode := 16#8013;
            END_IF;
        16#8013:
            IF Reset AND NOT R_TRIGatReset.Q AND NOT S_AutoReset THEN
                DiagCode := 16#C007;
            ELSIF NOT S_OSSD_In THEN
                DiagCode := 16#8012;
            ELSIF S_OSSD_In AND (R_TRIGatReset.Q OR S_AutoReset) THEN
                DiagCode := 16#8000;
            END_IF;
        16#8020:
            IF Timer1.Q THEN
                DiagCode := 16#C020;
            ELSIF NOT S_OSSD_In THEN
                DiagCode := 16#8030;
                Timer2(IN:=FALSE);
            END_IF;
        16#8030:
            IF Timer2.Q THEN
                DiagCode := 16#C030;
            ELSIF S_OSSD_In THEN
                DiagCode := 16#8000;
            END_IF;
        16#C000:
            IF Reset AND NOT R_TRIGatReset.Q THEN
                DiagCode := 16#C006;
            ELSIF R_TRIGatReset.Q AND TestTime <= T#150ms THEN
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
            IF Reset AND NOT R_TRIGatReset.Q THEN
                DiagCode := 16#C003;
            ELSIF R_TRIGatReset.Q AND NOT NoExternalTest THEN
                DiagCode := 16#8004;
            ELSIF S_OSSD_In AND (R_TRIGatReset.Q AND NoExternalTest) THEN
                DiagCode := 16#8010;
            END_IF;
        16#C020:
            IF Reset AND NOT R_TRIGatReset.Q THEN
                DiagCode := 16#C004;
            ELSIF R_TRIGatReset.Q AND NOT NoExternalTest THEN
                DiagCode := 16#8004;
            ELSIF S_OSSD_In AND (R_TRIGatReset.Q AND NoExternalTest) THEN
                DiagCode := 16#8010;
            END_IF;
    END_CASE;
END_IF;

CASE DiagCode OF
    16#0000:
        Ready := FALSE;
        S_OSSD_Out := FALSE;
        S_TestOut := TRUE;
        TestPossible := FALSE;
        TestExecuted := FALSE;
        Error := FALSE;
    16#8000:
        Ready := TRUE;
        S_OSSD_Out := TRUE;
        S_TestOut := TRUE;
        TestPossible := TRUE;
        TestExecuted := TRUE;
        Error := FALSE;
    16#8001, 16#8002, 16#8003, 16#8004, 16#8005, 16#8006:
        Ready := TRUE;
        S_OSSD_Out := FALSE;
        S_TestOut := TRUE;
        TestPossible := FALSE;
        TestExecuted := FALSE;
        Error := FALSE;
    16#8010:
        Ready := TRUE;
        S_OSSD_Out := TRUE;
        S_TestOut := TRUE;
        TestPossible := TRUE;
        TestExecuted := FALSE;
        Error := FALSE;
    16#8012, 16#8013:
        Ready := TRUE;
        S_OSSD_Out := FALSE;
        S_TestOut := TRUE;
        TestPossible := FALSE;
        TestExecuted := TRUE;
        Error := FALSE;
    16#8020:
        Ready := TRUE;
        S_OSSD_Out := TRUE;
        S_TestOut := FALSE;
        TestPossible := FALSE;
        TestExecuted := FALSE;
        Error := FALSE;
        Timer1(IN:=TRUE, PT:=TestTime);
    16#8030:
        Ready := TRUE;
        S_OSSD_Out := TRUE;
        S_TestOut := TRUE;
        TestPossible := FALSE;
        TestExecuted := FALSE;
        Error := FALSE;
        Timer2(IN:=TRUE, PT:=TestTime);
    16#C000, 16#C001, 16#C002, 16#C003, 16#C004, 16#C005, 16#C006, 16#C010, 16#C020:
        Ready := TRUE;
        S_OSSD_Out := FALSE;
        S_TestOut := TRUE;
        TestPossible := FALSE;
        TestExecuted := FALSE;
        Error := TRUE;
    16#C007:
        Ready := TRUE;
        S_OSSD_Out := FALSE;
        S_TestOut := TRUE;
        TestPossible := FALSE;
        TestExecuted := TRUE;
        Error := TRUE;
END_CASE;

END_FUNCTION_BLOCK
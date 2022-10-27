FUNCTION_BLOCK SF_GuardLocking2
VAR_INPUT
        Activate          : BOOL;
        S_GuardMonitoring : SAFEBOOL;
        S_SafetyActive    : SAFEBOOL;
        S_GuardLock       : SAFEBOOL;
        UnlockRequest     : BOOL;
        S_StartReset      : SAFEBOOL;
        S_AutoReset       : SAFEBOOL;
        Reset             : BOOL;
 END_VAR

 VAR_OUTPUT
    Ready             : BOOL;
    S_GuardLocked     : SAFEBOOL;
    S_UnlockGuard     : SAFEBOOL;
    Error             : BOOL;
         DiagCode                  : WORD:=16#0000;
 END_VAR

VAR
        R_TRIGatReset: R_TRIG;
        R_TRIGatUnlockRequest: R_TRIG;
END_VAR

R_TRIGatReset(CLK:=Reset);
R_TRIGatUnlockRequest(CLK:=UnlockRequest);

IF NOT Activate THEN
    DiagCode := 16#0000;
END_IF;

CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
16#8000:
    IF NOT S_GuardLock OR NOT S_GuardMonitoring THEN
        DiagCode := 16#C004;
    ELSIF R_TRIGatUnlockRequest.Q AND S_SafetyActive THEN
        DiagCode := 16#8013;
    END_IF;
16#8001:
    IF Reset AND NOT R_TRIGatReset.Q AND NOT S_StartReset THEN
        DiagCode := 16#C001;
    ELSIF NOT S_GuardLock OR NOT S_GuardMonitoring THEN
        DiagCode := 16#8011;
    ELSIF (R_TRIGatReset.Q OR S_StartReset) AND S_GuardMonitoring AND S_GuardLock THEN
        DiagCode := 16#8000;
    END_IF;
16#8003:
    IF Reset AND NOT R_TRIGatReset.Q AND NOT S_AutoReset THEN
        DiagCode := 16#C003;
    ELSIF NOT S_GuardMonitoring OR NOT S_GuardLock THEN
        DiagCode := 16#8011;
    ELSIF R_TRIGatReset.Q OR S_AutoReset THEN
        DiagCode := 16#8000;
    END_IF;
16#8011:
    IF NOT S_SafetyActive AND (NOT S_GuardMonitoring OR NOT S_GuardLock) THEN
        DiagCode := 16#C004;
    ELSIF (S_SafetyActive AND UnlockRequest) OR NOT S_GuardMonitoring THEN
        DiagCode := 16#8012;
    ELSIF S_GuardMonitoring AND S_GuardLock THEN
        DiagCode := 16#8003;
    END_IF;
16#8012:
    IF S_GuardMonitoring THEN
        DiagCode := 16#8013;
    ELSIF NOT S_SafetyActive AND NOT S_GuardMonitoring THEN
        DiagCode := 16#C004;
    END_IF;
16#8013:
    IF NOT S_GuardMonitoring THEN
        DiagCode := 16#8012;
    ELSIF NOT UnlockRequest THEN
        DiagCode := 16#8011;
    END_IF;
16#8014:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C002;
    ELSIF NOT S_SafetyActive THEN
        DiagCode := 16#C004;
    ELSIF R_TRIGatReset.Q THEN
        DiagCode := 16#8011;
    END_IF;
16#C001:
    IF NOT Reset THEN
        DiagCode := 16#8001;
    END_IF;
16#C002:
    IF NOT Reset THEN
        DiagCode := 16#8014;
    END_IF;
16#C003:
    IF NOT Reset THEN
        DiagCode := 16#8003;
    END_IF;
16#C004:
    IF S_SafetyActive THEN
        DiagCode := 16#8014;
    END_IF;
END_CASE;


CASE DiagCode OF
16#0000:
    Ready := FALSE;
    S_GuardLocked := FALSE;
    S_UnlockGuard := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    S_GuardLocked := TRUE;
    S_UnlockGuard := FALSE;
    Error := FALSE;
16#8001,
16#8003,
16#8011,
16#8014:
    Ready := TRUE;
    S_GuardLocked := FALSE;
    S_UnlockGuard := FALSE;
    Error := FALSE;
16#8012,
16#8013:
    Ready := TRUE;
    S_GuardLocked := FALSE;
    S_UnlockGuard := TRUE;
    Error := FALSE;
16#C001,
16#C002,
16#C003,
16#C004:
    Ready := TRUE;
    S_GuardLocked := FALSE;
    S_UnlockGuard := FALSE;
    Error := TRUE;
END_CASE;

END_FUNCTION_BLOCK

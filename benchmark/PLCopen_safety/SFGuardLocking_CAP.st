PROGRAM Main
VAR_INPUT
    Activate : BOOL;
    SGuardMonitoring : SAFEBOOL;
    SSafetyActive : SAFEBOOL;
    SGuardLock : SAFEBOOL;
    UnlockRequest : BOOL;
    SStartReset : SAFEBOOL;
    SAutoReset : SAFEBOOL;
    Reset : BOOL;
END_VAR
VAR
    SFGuardLocking : SFGuardLocking;
END_VAR
SFGuardLocking(Activate:=Activate,SGuardMonitoring:=SGuardMonitoring,SSafetyActive:=SSafetyActive,SGuardLock:=SGuardLock,
UnlockRequest:=UnlockRequest,SStartReset:=SStartReset,SAutoReset:=SAutoReset,Reset:=Reset);
END_PROGRAM

FUNCTION_BLOCK SFGuardLocking
VAR_INPUT
    Activate : BOOL;
    SGuardMonitoring : SAFEBOOL;
    SSafetyActive : SAFEBOOL;
    SGuardLock : SAFEBOOL;
    UnlockRequest : BOOL;
    SStartReset : SAFEBOOL;
    SAutoReset : SAFEBOOL;
    Reset : BOOL;
END_VAR
VAR
    RTRIGatResetQ : BOOL;
    RTRIGatResetM : BOOL;
    RTRIGatUnlockRequestQ : BOOL;
    RTRIGatUnlockRequestM : BOOL;
END_VAR
VAR_OUTPUT
    Ready : BOOL;
    SGuardLocked : SAFEBOOL;
    SUnlockGuard : SAFEBOOL;
    Error : BOOL;
    DiagCode : WORD;
END_VAR
RTRIGatResetQ := Reset AND NOT RTRIGatResetM;
RTRIGatResetM := Reset;

RTRIGatUnlockRequestQ := UnlockRequest AND NOT RTRIGatUnlockRequestM;
RTRIGatUnlockRequestM := UnlockRequest;

IF NOT Activate THEN
    DiagCode := 16#0000;
END_IF;
CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
16#8000:
    IF NOT SGuardLock OR NOT SGuardMonitoring THEN
        DiagCode := 16#C004;
    ELSIF RTRIGatUnlockRequestQ AND SSafetyActive THEN
        DiagCode := 16#8013;
    END_IF;
16#8001:
    IF Reset AND NOT RTRIGatResetQ AND NOT SStartReset THEN
        DiagCode := 16#C001;
    ELSIF NOT SGuardLock OR NOT SGuardMonitoring THEN
        DiagCode := 16#8011;
    ELSIF (RTRIGatResetQ OR SStartReset) AND SGuardMonitoring AND SGuardLock THEN
        DiagCode := 16#8000;
    END_IF;
16#8003:
    IF change(Reset AND NOT RTRIGatResetQ AND NOT SAutoReset, TRUE) THEN
        DiagCode := 16#C003;
    ELSIF NOT SGuardMonitoring OR NOT SGuardLock THEN
        DiagCode := 16#8011;
    ELSIF RTRIGatResetQ OR SAutoReset THEN
        DiagCode := 16#8000;
    END_IF;
16#8011:
    IF NOT SSafetyActive AND (NOT SGuardMonitoring OR NOT SGuardLock) THEN
        DiagCode := 16#C004;
    ELSIF (SSafetyActive AND UnlockRequest) OR NOT SGuardMonitoring THEN
        DiagCode := 16#8012;
    ELSIF SGuardMonitoring AND SGuardLock THEN
        DiagCode := 16#8003;
    END_IF;
16#8012:
    IF SGuardMonitoring THEN
        DiagCode := 16#8013;
    ELSIF NOT SSafetyActive AND NOT SGuardMonitoring THEN
        DiagCode := 16#C004;
    END_IF;
16#8013:
    IF NOT SGuardMonitoring THEN
        DiagCode := 16#8012;
    ELSIF NOT UnlockRequest THEN
        DiagCode := 16#8011;
    END_IF;
16#8014:
    IF Reset AND NOT RTRIGatResetQ THEN
        DiagCode := 16#C002;
    ELSIF NOT SSafetyActive THEN
        DiagCode := 16#C004;
    ELSIF RTRIGatResetQ THEN
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
    IF SSafetyActive THEN
        DiagCode := 16#8014;
    END_IF;
END_CASE;
CASE DiagCode OF
16#0000:
    Ready := FALSE;
    SGuardLocked := FALSE;
    SUnlockGuard := FALSE;
    Error := FALSE;
16#8000:
    Ready := TRUE;
    SGuardLocked := TRUE;
    SUnlockGuard := FALSE;
    Error := FALSE;
16#8001,
16#8003,
16#8011,
16#8014:
    Ready := TRUE;
    SGuardLocked := FALSE;
    SUnlockGuard := FALSE;
    Error := FALSE;
16#8012,
16#8013:
    Ready := TRUE;
    SGuardLocked := FALSE;
    SUnlockGuard := TRUE;
    Error := FALSE;
16#C001,
16#C002,
16#C003,
16#C004:
    Ready := TRUE;
    SGuardLocked := FALSE;
    SUnlockGuard := FALSE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK
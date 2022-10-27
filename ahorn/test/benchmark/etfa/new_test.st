PROGRAM Test
VAR_INPUT
    Activate : BOOL;
    SChannelNC : BOOL;
    SChannelNO : BOOL;
END_VAR
VAR
    SFAntivalent1 : SFAntivalent;
END_VAR
SFAntivalent1(Activate:=Activate,
                 SChannelNC:=SChannelNC,
                 SChannelNO:=SChannelNO);
END_PROGRAM

FUNCTION_BLOCK SFAntivalent
VAR_INPUT
    Activate : BOOL;
    SChannelNC : SAFEBOOL;
    SChannelNO : SAFEBOOL;
END_VAR
VAR_OUTPUT
    DiagCode : WORD;
END_VAR
CASE DiagCode OF
16#0000:
    DiagCode := change(16#8001,16#8002);
16#8001:
    IF change(SChannelNC AND SChannelNO, FALSE) THEN
        DiagCode := 16#8004;
    ELSIF SChannelNC AND NOT SChannelNO THEN
        DiagCode := 16#8000;
    END_IF;
16#8004:
    DiagCode := 16#8000;
END_CASE;
END_FUNCTION_BLOCK
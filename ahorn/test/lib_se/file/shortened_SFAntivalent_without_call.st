PROGRAM SFAntivalent
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
    DiagCode := 16#8001;
16#8001:
    IF SChannelNC AND SChannelNO THEN
        DiagCode := 16#8004;
    ELSIF SChannelNC AND NOT SChannelNO THEN
        DiagCode := 16#8000;
    END_IF;
16#8004:
    DiagCode := 16#8000;
END_CASE;
END_PROGRAM

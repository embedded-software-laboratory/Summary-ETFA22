FUNCTION_BLOCK SF_Muting_Seq
 VAR_INPUT
    Activate        : BOOL := FALSE;
    S_AOPD_In       : SAFEBOOL := FALSE;
    MutingSwitch11  : BOOL := FALSE;
    MutingSwitch12  : BOOL := FALSE;
    MutingSwitch21  : BOOL := FALSE;
    MutingSwitch22  : BOOL := FALSE;
    S_MutingLamp    : SAFEBOOL := FALSE;
    DiscTime11_12   : TIME := T#0s;
    DiscTime21_22   : TIME := T#0s;
    MaxMutingTime   : TIME := T#0s;
    MutingEnable    : BOOL := FALSE;
    S_StartReset    : SAFEBOOL := FALSE;
    Reset           : BOOL := FALSE;
 END_VAR
 VAR_OUTPUT
   Ready          : BOOL := FALSE;
   S_AOPD_Out     : SAFEBOOL := FALSE;
   S_MutingActive : SAFEBOOL := FALSE;
   Error          : BOOL := FALSE;
   DiagCode       : WORD := 16#0000;
 END_VAR
 VAR
    R_TRIGatReset  : R_TRIG;
    R_TRIGatMS_11  : R_TRIG;
    R_TRIGatMS_12  : R_TRIG;
    R_TRIGatMS_21  : R_TRIG;
    R_TRIGatMS_22  : R_TRIG;
    F_TRIGatMS_11  : F_TRIG;
    F_TRIGatMS_12  : F_TRIG;
    F_TRIGatMS_21  : F_TRIG;
    F_TRIGatMS_22  : F_TRIG;
    MutingTimer    : TON;
 END_VAR
 
R_TRIGatReset(CLK:=Reset);
R_TRIGatMS_11(CLK:=MutingSwitch11);
R_TRIGatMS_12(CLK:=MutingSwitch12);
R_TRIGatMS_21(CLK:=MutingSwitch21);
R_TRIGatMS_22(CLK:=MutingSwitch22);
F_TRIGatMS_11(CLK:=MutingSwitch11);
F_TRIGatMS_12(CLK:=MutingSwitch12);
F_TRIGatMS_21(CLK:=MutingSwitch21);
F_TRIGatMS_22(CLK:=MutingSwitch22);

IF NOT Activate THEN
    DiagCode := 16#0000;
ELSE

CASE DiagCode OF
16#0000:
    IF Activate THEN
        DiagCode := 16#8001;
    END_IF;
16#8000:

    IF (NOT MutingEnable AND R_TRIGatMS_11.Q) OR (NOT MutingEnable AND R_TRIGatMS_22.Q) OR (MutingSwitch12 OR MutingSwitch21) OR (MutingSwitch11 AND MutingSwitch22) THEN
        (* Wrong muting sequence *)
        DiagCode := 16#C004;
    ELSIF NOT S_AOPD_In THEN
        DiagCode := 16#8002;
    ELSIF NOT S_MutingLamp THEN
        DiagCode := 16#C003;
    ELSIF MutingEnable AND (R_TRIGatMS_11.Q AND NOT MutingSwitch12 AND NOT MutingSwitch21 AND NOT MutingSwitch22) THEN
        DiagCode := 16#8011;
        MutingTimer(IN:=TRUE, PT:=MaxMutingTime);
    ELSIF MutingEnable AND (NOT MutingSwitch11 AND NOT MutingSwitch12 AND NOT MutingSwitch21 AND R_TRIGatMS_22.Q) THEN
        DiagCode := 16#8122;
        MutingTimer(IN:=TRUE, PT:=MaxMutingTime);
    END_IF;
16#8001:
    IF Reset AND NOT R_TRIGatReset.Q AND NOT S_StartReset THEN
        DiagCode := 16#C001;
(*  
    ELSIF (Time parameters out of range)
        DiagCode := 16#C005; 
*)
    ELSIF R_TRIGatReset.Q OR S_StartReset THEN
        DiagCode := 16#8005;
    END_IF;
16#8002:
    IF S_AOPD_In THEN
        DiagCode := 16#8003;
    END_IF;
16#8003:
    IF Reset AND NOT R_TRIGatReset.Q THEN
        DiagCode := 16#C002;
    ELSIF R_TRIGatReset.Q THEN
        DiagCode := 16#8005;
    END_IF;
16#8005:
    IF NOT S_AOPD_In THEN
        DiagCode := 16#8002;
    ELSIF NOT S_MutingLamp THEN
        DiagCode := 16#C003;
    ELSIF S_AOPD_In THEN
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
    IF S_MutingLamp THEN
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
           ELSIF MutingTimer.Q THEN
               DiagCode := 16#C006;
           ELSIF NOT S_AOPD_In THEN
               DiagCode := 16#8002;
           ELSIF NOT S_MutingLamp THEN
               DiagCode := 16#C003;
           ELSIF MutingEnable AND (MutingSwitch11 AND R_TRIGatMS_12.Q AND NOT MutingSwitch21 AND NOT MutingSwitch22) THEN
               DiagCode := 16#8012;
           END_IF;
       16#8012:
           IF R_TRIGatMS_11.Q OR R_TRIGatMS_12.Q OR F_TRIGatMS_22.Q THEN
               DiagCode := 16#C104;
           ELSIF MutingTimer.Q THEN
               DiagCode := 16#C006;
           ELSIF NOT S_MutingLamp THEN
               DiagCode := 16#C003;
           ELSIF NOT MutingSwitch11 AND NOT MutingSwitch12 AND F_TRIGatMS_21.Q AND MutingSwitch22 THEN
               MutingTimer(IN:=FALSE, PT:=MaxMutingTime);
               DiagCode := 16#8000;
           END_IF;
       16#8122:
           IF NOT MutingEnable OR MutingSwitch11 OR MutingSwitch12 OR NOT MutingSwitch22 THEN
               DiagCode := 16#C104;
           ELSIF MutingTimer.Q THEN
               DiagCode := 16#C006;
           ELSIF NOT S_AOPD_In THEN
               DiagCode := 16#8002;
           ELSIF NOT S_MutingLamp THEN
               DiagCode := 16#C003;
           ELSIF MutingEnable AND (NOT MutingSwitch11 AND NOT MutingSwitch12 AND R_TRIGatMS_21.Q AND MutingSwitch22) THEN
               DiagCode := 16#8112;
           END_IF;
       16#8112:
           IF F_TRIGatMS_11.Q OR R_TRIGatMS_21.Q OR R_TRIGatMS_22.Q THEN
               DiagCode := 16#C104;
           ELSIF MutingTimer.Q THEN
               DiagCode := 16#C006;
           ELSIF NOT S_MutingLamp THEN
               DiagCode := 16#C003;
           ELSIF MutingSwitch11 AND F_TRIGatMS_12.Q AND NOT MutingSwitch21 AND NOT MutingSwitch22 THEN
               DiagCode := 16#8000;
               MutingTimer(IN:=FALSE, PT:=MaxMutingTime);
           END_IF;
       END_CASE;
    END_IF;
END_CASE;
END_IF;

CASE DiagCode OF
16#0000:
    Ready := FALSE;
    S_AOPD_Out := FALSE;
    S_MutingActive := FALSE;
    Error := FALSE;
16#8000,
16#8011,
16#8122:
    Ready := TRUE;
    S_AOPD_Out := TRUE;
    S_MutingActive := FALSE;
    Error := FALSE;
16#8001,
16#8002,
16#8003,
16#8005:
    Ready := TRUE;
    S_AOPD_Out := FALSE;
    S_MutingActive := FALSE;
    Error := FALSE;
16#8012,
16#8112:
    Ready := TRUE;
    S_AOPD_Out := TRUE;
    S_MutingActive := TRUE;
    Error := FALSE;
ELSE
    Ready := TRUE;
    S_AOPD_Out := FALSE;
    S_MutingActive := FALSE;
    Error := TRUE;
END_CASE;
END_FUNCTION_BLOCK
FUNCTION_BLOCK SF_TwoHandControlTypeII2
 VAR_INPUT
        Activate       : BOOL := FALSE;
        S_Button1      : SAFEBOOL := FALSE;
        S_Button2      : SAFEBOOL := FALSE;
 END_VAR
 VAR_OUTPUT
        Ready          : BOOL := FALSE;
        S_TwoHandOut   : BOOL := FALSE;
        Error          : BOOL := FALSE;
        DiagCode       : WORD := 16#0;
 END_VAR
 
 IF NOT Activate THEN
     DiagCode := 16#0000;
 ELSE
 
 CASE DiagCode OF
 16#0000: 
     IF Activate THEN
          DiagCode := 16#8001;
     END_IF;
	 
 16#8001:
     IF S_Button1 AND S_Button2 THEN
	     DiagCode := 16#C003;
     ELSIF S_Button1 THEN
	     DiagCode := 16#C001;
	 ELSIF S_Button2 THEN
	     DiagCode := 16#C002;
     ELSE
	     DiagCode := 16#8004;
     END_IF;
 16#8004:
     IF S_Button1 AND S_Button2 THEN
	     DiagCode := 16#8000;
     ELSIF S_Button1 THEN
	     DiagCode := 16#8005;
	 ELSIF S_Button2 THEN
	     DiagCode := 16#8006;
	 END_IF;
 16#8005:
     IF NOT (S_Button1 OR S_Button2) THEN
	     DiagCode := 16#8004;
	 ELSIF NOT S_Button1 AND S_Button2 THEN
	     DiagCode := 16#8019;
	 ELSIF S_Button1 AND S_Button2 THEN
	     DiagCode := 16#8000;
     END_IF;
 16#8006:
     IF NOT (S_Button1 OR S_Button2) THEN
	     DiagCode := 16#8004;
     ELSIF S_Button1 AND NOT S_Button2 THEN
	     DiagCode := 16#8019;
	 ELSIF S_Button1 AND S_Button2 THEN
	     DiagCode := 16#8000;
     END_IF;
 16#8007:
     IF S_Button1 AND S_Button2 THEN
	     DiagCode := 16#8009;
	 ELSIF NOT S_Button1 AND S_Button2 THEN 
	     DiagCode := 16#8008;
	 ELSIF NOT (S_Button1 OR S_Button2) THEN
	     DiagCode := 16#8004;
	 END_IF;
 16#8008:
     IF S_Button1 AND S_Button2 THEN
         DiagCode := 16#8009;
     ELSIF S_Button1 AND NOT S_Button2 THEN
	     DiagCode := 16#8007;		 
     ELSIF NOT (S_Button1 OR S_Button2) THEN
	     DiagCode := 16#8004;
	 END_IF;
 16#8009:
     IF NOT S_Button1 AND S_Button2 THEN
	    DiagCode := 16#8008;
	 ELSIF S_Button1 AND NOT S_Button2 THEN
	     DiagCode := 16#8007;
	 ELSIF NOT (S_Button1 OR S_Button2) THEN
	     DiagCode := 16#8004;
	 END_IF;
 16#8019:
     IF NOT (S_Button1 OR S_Button2) THEN
	     DiagCode := 16#8004;
     END_IF;
 16#8000:
     IF S_Button1 AND NOT S_Button2 THEN
	     DiagCode := 16#8007;
	 ELSIF NOT S_Button1 AND S_Button2 THEN 
	     DiagCode := 16#8008;
	 ELSIF NOT (S_Button1 OR S_Button2) THEN
	     DiagCode := 16#8004;
	 END_IF;
 16#C001,
 16#C002,
 16#C003:
     IF NOT (S_Button1 OR S_Button2) THEN
	     DiagCode := 16#8004;
	 END_IF;
	 
 END_CASE;
 END_IF;

 CASE DiagCode OF
  16#0000:
      Ready := FALSE;
      ERROR := FALSE;
      S_TwoHandOut := FALSE;
 16#8000:
      Ready := TRUE;
      ERROR := FALSE;
      S_TwoHandOut := TRUE; 
 16#8001,
 16#8004,
 16#8005,
 16#8006,
 16#8007,
 16#8008,
 16#8009,
 16#8019:
      Ready := TRUE;
      ERROR := FALSE;
      S_TwoHandOut := FALSE;
 16#C001,
 16#C002,
 16#C003:
      Ready := TRUE;
      ERROR := TRUE;
      S_TwoHandOut := FALSE;
 END_CASE;
 
END_FUNCTION_BLOCK

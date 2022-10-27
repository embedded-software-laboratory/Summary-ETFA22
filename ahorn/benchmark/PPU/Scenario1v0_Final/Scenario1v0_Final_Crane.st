FUNCTION_BLOCK Crane
    VAR_INPUT  CraneDown : BOOL; END_VAR 
    VAR_OUTPUT  CraneLower : BOOL; END_VAR 
    VAR_INPUT  CraneOnConveyor : BOOL; END_VAR 
    VAR_INPUT  CraneOnMagazin : BOOL; END_VAR 
    VAR_INPUT  CraneSucked : BOOL; END_VAR 
    VAR_OUTPUT  CraneTurnClockwise : BOOL; END_VAR 
    VAR_OUTPUT  CraneTurnCounterclockwise : BOOL; END_VAR 
    VAR_INPUT  CraneUp : BOOL; END_VAR 
    VAR_OUTPUT  MagazinVacuumOff : BOOL; END_VAR 
    VAR_OUTPUT  MagazinVacuumOn : BOOL; END_VAR 
    VAR  SFCInit : BOOL; END_VAR 
    VAR_INPUT  SFCReset : BOOL; END_VAR 
    VAR_INPUT  SliderMovedOut : BOOL; END_VAR 
    VAR_INPUT  SliderNotMovedOut : BOOL; END_VAR 
    VAR_INPUT  StartButtonMagazin : BOOL; END_VAR 
    VAR_OUTPUT  StartCommandCrane : BOOL; END_VAR 
    VAR_INPUT  StartVar : BOOL; END_VAR 
    VAR  TimeDelay_Timer : TON; END_VAR 
    VAR  TimeDelay_Timer_Duration : TIME := TIME#50.0ms; END_VAR 
    VAR  TimeDelay_Timer_interconnect : BOOL; END_VAR 
    VAR_INPUT  WorkpieceReady : BOOL; END_VAR 
    VAR  State : Crane_states_t; END_VAR
    VAR  Transit : BOOL; END_VAR 
    VAR  interconnectCraneStartCommand : BOOL; END_VAR 
    
    CASE State OF
        Crane_states_t#Crane_Init:
            Transit := FALSE;
            CraneLower := TRUE;
            interconnectCraneStartCommand := FALSE;
            IF CraneDown THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Init_2;
            END_IF;
        
        Crane_states_t#Crane_Init_2:
            Transit := FALSE;
            CraneLower := FALSE;
            IF CraneUp THEN
                Transit := TRUE;
                State := Crane_states_t#Interstep;
            END_IF;
        
        Crane_states_t#Crane_Lift_Conveyor:
            Transit := FALSE;
            CraneLower := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#Interstep;
            END_IF;
        
        Crane_states_t#Crane_Lift_Magazine:
            Transit := FALSE;
            CraneLower := FALSE;
            IF CraneUp THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Turn_Left;
            END_IF;
        
        Crane_states_t#Crane_On_Conveyor:
            Transit := FALSE;
            CraneTurnCounterclockwise := FALSE;
            CraneTurnClockwise := FALSE;
            CraneLower := TRUE;
            IF CraneDown THEN
                Transit := TRUE;
                State := Crane_states_t#release;
            END_IF;
        
        Crane_states_t#Crane_Stop:
            Transit := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#Start_Crane;
            END_IF;
        
        Crane_states_t#Crane_Turn_Left:
            Transit := FALSE;
            CraneTurnCounterclockwise := TRUE;
            CraneTurnClockwise := FALSE;
            IF CraneOnConveyor THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_On_Conveyor;
            END_IF;
        
        Crane_states_t#Init:
            Transit := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#Start_Crane;
            END_IF;
        
        Crane_states_t#Interstep:
            Transit := FALSE;
            StartCommandCrane := TRUE;
            IF StartVar THEN
                Transit := TRUE;
                State := Crane_states_t#Interstep_2;
            END_IF;
        
        Crane_states_t#Interstep_2:
            Transit := FALSE;
            IF SliderMovedOut THEN
                Transit := TRUE;
                State := Crane_states_t#TimeDelay;
            END_IF;
        
        Crane_states_t#Interstep_Check_Workpiece:
            Transit := FALSE;
            IF WorkpieceReady THEN
                Transit := TRUE;
                State:= Crane_states_t#Magazin_Stop;
            ELSIF NOT WorkpieceReady THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Stop;
            END_IF;
        
        Crane_states_t#Magazin_Stop:
            Transit := FALSE;
            CraneTurnClockwise := FALSE;
            CraneTurnCounterclockwise := FALSE;
            MagazinVacuumOn := TRUE;
            MagazinVacuumOff := FALSE;
            CraneLower := TRUE;
            IF CraneSucked THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Lift_Magazine;
            END_IF;
        
        Crane_states_t#Start_Crane:
            Transit := FALSE;
            CraneLower := FALSE;
            MagazinVacuumOff := TRUE;
            MagazinVacuumOn := FALSE;
            CraneTurnCounterclockwise := FALSE;
            CraneTurnClockwise := FALSE;
            StartVar := FALSE;
            StartCommandCrane := FALSE;
            IF (StartButtonMagazin = TRUE) THEN
                interconnectCraneStartCommand := TRUE;
            END_IF;
            IF interconnectCraneStartCommand THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Init;
            END_IF;
        
        Crane_states_t#TimeDelay:
            Transit := FALSE;
            TimeDelay_Timer(IN := TRUE, PT := TimeDelay_Timer_Duration);
            TimeDelay_Timer_interconnect := TimeDelay_Timer.Q;
            IF TimeDelay_Timer_interconnect THEN
                Transit := TRUE;
                State := Crane_states_t#Turn_Right;
            END_IF;
        
        Crane_states_t#Turn_Right:
            Transit := FALSE;
            CraneTurnClockwise := TRUE;
            CraneTurnCounterclockwise := FALSE;
            IF CraneOnMagazin THEN
                Transit := TRUE;
                State := Crane_states_t#Interstep_Check_Workpiece;
            END_IF;
        
        Crane_states_t#release:
            Transit := FALSE;
            MagazinVacuumOff := TRUE;
            MagazinVacuumOn := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Lift_Conveyor;
            END_IF;
        
            END_CASE;
END_FUNCTION_BLOCK


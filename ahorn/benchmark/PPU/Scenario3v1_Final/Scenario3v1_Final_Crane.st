FUNCTION_BLOCK Crane
    VAR_INPUT  CraneDown : BOOL; END_VAR 
    VAR_OUTPUT  CraneLower : BOOL; END_VAR 
    VAR_INPUT  CraneOnConveyor : BOOL; END_VAR 
    VAR_INPUT  CraneOnMagazin : BOOL; END_VAR 
    VAR_INPUT  CranePositionStamp : BOOL; END_VAR 
    VAR_INPUT  CraneSucked : BOOL; END_VAR 
    VAR_OUTPUT  CraneTurnClockwise : BOOL; END_VAR 
    VAR_OUTPUT  CraneTurnCounterclockwise : BOOL; END_VAR 
    VAR_INPUT  CraneUp : BOOL; END_VAR 
    VAR  Duration1 : TIME := TIME#1s500.0ms; END_VAR
    VAR_INPUT  MagazinCapacitiveSensor : BOOL; END_VAR 
    VAR_OUTPUT  MagazinVacuumOff : BOOL; END_VAR 
    VAR_OUTPUT  MagazinVacuumOn : BOOL; END_VAR 
    VAR  SFCInit : BOOL; END_VAR 
    VAR_INPUT  SFCReset : BOOL; END_VAR 
    VAR_INPUT  SliderMovedOut : BOOL; END_VAR 
    VAR_INPUT  SliderNotMovedOut : BOOL; END_VAR 
    VAR_INPUT  StampLowered : BOOL; END_VAR 
    VAR_INPUT  StampSliderFilled : BOOL; END_VAR 
    VAR_INPUT  StartButtonMagazin : BOOL; END_VAR 
    VAR_OUTPUT  StartCommandCrane : BOOL; END_VAR 
    VAR_INPUT  StartVar : BOOL; END_VAR 
    VAR  TimeDelay_Timer : TON; END_VAR 
    VAR  TimeDelay_Timer_Duration : TIME := TIME#50.0ms; END_VAR 
    VAR  TimeDelay_Timer_interconnect : BOOL; END_VAR 
    VAR  Timer1 : TON; END_VAR 
    VAR_INPUT  WorkpieceReady : BOOL; END_VAR 
    VAR  State : Crane_states_t; END_VAR 
    VAR  Transit : BOOL; END_VAR 
    VAR  actualtime1 : TIME; END_VAR 
    VAR  interconnect : BOOL; END_VAR 
    VAR  interconnectCraneStartCommand : BOOL; END_VAR 
    
    CASE State OF 
        Crane_states_t#Crane_Go_Up:
            Transit := FALSE;
            CraneLower := FALSE;
            IF CraneUp THEN
                Transit := TRUE;
                State := Crane_states_t#pause;
            END_IF;

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

        Crane_states_t#Crane_Lift_At_Stamp:
            Transit := FALSE;
            CraneLower := FALSE;
            IF CraneUp THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Turn_Left_From_Stamp;
            END_IF;

        Crane_states_t#Crane_Lift_Conveyor:
            Transit := FALSE;
            CraneLower := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#Interstep;
            END_IF;

        
        Crane_states_t#Crane_Lift_Magazin:
            Transit := FALSE;
            CraneLower := FALSE;
            IF CraneUp THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Turn_Left_NOT_Metallic;
            END_IF;

        
        Crane_states_t#Crane_Lift_Magazin_Metallic:
            Transit := FALSE;
            CraneLower := FALSE;
            IF CraneUp THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Turn_Left_Metallic;
            END_IF;

        
        Crane_states_t#Crane_Lower:
            Transit := FALSE;
            MagazinVacuumOn := TRUE;
            MagazinVacuumOff := FALSE;
            CraneLower := TRUE;
            IF CraneSucked THEN
                Transit := TRUE;
                State := Crane_states_t#Step0;
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

        
        Crane_states_t#Crane_On_Conveyor_Metallic:
            Transit := FALSE;
            CraneTurnCounterclockwise := FALSE;
            CraneTurnClockwise := FALSE;
            CraneLower := TRUE;
            IF CraneDown THEN
                Transit := TRUE;
                State := Crane_states_t#release;
            END_IF;

        Crane_states_t#Crane_On_Stamp_Metallic:
            Transit := FALSE;
            CraneTurnCounterclockwise := FALSE;
            CraneTurnClockwise := FALSE;
            CraneLower := TRUE;
            IF CraneDown THEN
                Transit := TRUE;
                State := Crane_states_t#release_Workpiece;
            END_IF;

        
        Crane_states_t#Crane_Turn_Left_From_Stamp:
            Transit := FALSE;
            CraneTurnClockwise := TRUE;
            CraneTurnCounterclockwise := FALSE;
            IF CraneOnConveyor THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_On_Conveyor_Metallic;
            END_IF;

        
        Crane_states_t#Crane_Turn_Left_Metallic:
            Transit := FALSE;
            CraneTurnCounterclockwise := TRUE;
            CraneTurnClockwise := FALSE;
            IF CranePositionStamp THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_On_Stamp_Metallic;
            END_IF;

        
        Crane_states_t#Crane_Turn_Left_NOT_Metallic:
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
            CraneTurnClockwise := FALSE;
            CraneTurnCounterClockwise := FALSE;
            IF WorkpieceReady THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Lower;
            ELSIF (NOT WorkpieceReady AND NOT StampSliderFilled) THEN
                Transit := TRUE;
                State := Crane_states_t#Step2;
            ELSIF (NOT WorkpieceReady AND StampSliderFilled) THEN
                Transit := TRUE;
                State := Crane_states_t#Wait_At_Stamp;
            END_IF;

        Crane_states_t#Lower_Crane:
            Transit := FALSE;
            CraneLower := TRUE;
            IF CraneDown THEN
                Transit := TRUE;
                State := Crane_states_t#Suck_At_Stamp;
            END_IF;

        Crane_states_t#Reset_interconnect:
            Transit := FALSE;
            interconnect := FALSE;
            Timer1(IN := FALSE, PT := TIME#1.0ms);
            IF SliderMovedOut THEN
                Transit := TRUE;
                State := Crane_states_t#Lower_Crane;
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

        Crane_states_t#Step0:
            Transit := FALSE;
            IF NOT MagazinCapacitiveSensor THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Lift_Magazin;
            ELSIF MagazinCapacitiveSensor THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Lift_Magazin_Metallic;
            END_IF;

        
        Crane_states_t#Step2:
            Transit := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#Start_Crane;
            END_IF;

        
        Crane_states_t#Suck_At_Stamp:
            Transit := FALSE;
            MagazinVacuumOn := TRUE;
            MagazinVacuumOff := FALSE;
            IF CraneSucked THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Lift_At_Stamp;
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

        
        Crane_states_t#Wait_At_Stamp:
            Transit := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#pause;
            END_IF;

        
        Crane_states_t#pause:
            Transit := FALSE;
            Timer1(IN := CraneUp, PT := Duration1);
            interconnect := Timer1.Q;
            IF interconnect THEN
                Transit := TRUE;
                State := Crane_states_t#Reset_interconnect;
            END_IF;

        
        Crane_states_t#release:
            Transit := FALSE;
            MagazinVacuumOff := TRUE;
            MagazinVacuumOn := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Lift_Conveyor;
            END_IF;

        
        Crane_states_t#release_Workpiece:
            Transit := FALSE;
            MagazinVacuumOff := TRUE;
            MagazinVacuumOn := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Crane_states_t#Crane_Go_Up;
            END_IF;
    END_CASE;
END_FUNCTION_BLOCK


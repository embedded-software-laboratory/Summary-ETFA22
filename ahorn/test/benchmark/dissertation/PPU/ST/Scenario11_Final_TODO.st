FUNCTION_BLOCK Conveyor
    
    VAR  
        Duration_Conveyor_Runtime : TIME := TIME#4500.0ms;
        Duration_Conveyor_Test : TIME := TIME#1000.0ms;
        SFCInit : BOOL := FALSE;
        Timer_Conveyor_Runtime : TON := (Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0);
        Timer_Conveyor_Test : TON := (Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0);
        interconnectConveyorStartCommand : BOOL := FALSE;
        interconnectConveyorTerminationCommand : BOOL := FALSE;
        interconnect_Conveyor_Runtime : BOOL := FALSE;
        interconnect_Conveyor_Test : BOOL := FALSE;
    END_VAR
    
    VAR  
        SFCPause : BOOL := FALSE;
    END_VAR
    
    VAR_INPUT  
        SFCReset : BOOL := FALSE;
        SorterLightbarrierCraneInterface : BOOL := FALSE;
        SorterStartButton : BOOL := FALSE;
        SorterSwitchManuellAutomatic : BOOL := FALSE;
        StartVar : BOOL := FALSE;
    END_VAR
    
    VAR_OUTPUT  
        SorterConveyorTowardsCrane : BOOL := FALSE;
        SorterConveyorTowardsStacker : BOOL := FALSE;
        SorterGreenLampConveyor : BOOL := FALSE;
        SorterWhiteLampConveyor : BOOL := FALSE;
        StartCommandConveyor : BOOL := FALSE;
    END_VAR
    
    VAR  
        __transit : BOOL := FALSE;
        _state : STATES_CONVEYOR := STATES_CONVEYOR#INIT;
    END_VAR
    
    
    ACTION Conveyor_init_2_active
        SorterConveyorTowardsStacker := FALSE;
        SorterConveyorTowardsCrane := FALSE;
        interconnect_Conveyor_Test := FALSE;
        Timer_Conveyor_Test(IN := FALSE, PT := TIME#0ms);
    END_ACTION
    ACTION Conveyor_Stop_Empty_Magazin_active
        SorterConveyorTowardsStacker := FALSE;
        SorterConveyorTowardsCrane := FALSE;
        interconnectConveyorStartCommand := FALSE;
    END_ACTION
    ACTION Conveyor_pause_active
        SorterConveyorTowardsStacker := FALSE;
        SorterConveyorTowardsCrane := FALSE;
        interconnect_Conveyor_Runtime := FALSE;
        Timer_Conveyor_Runtime(IN := FALSE, PT := TIME#0ms);
    END_ACTION
    ACTION Interstep_active
        StartCommandConveyor := TRUE;
    END_ACTION
    ACTION Conveyor_Stop_active
        SorterConveyorTowardsStacker := FALSE;
        SorterConveyorTowardsCrane := FALSE;
        SorterGreenLampConveyor := FALSE;
        interconnectConveyorStartCommand := FALSE;
    END_ACTION
    ACTION Runtime_Conveyor_active
        Timer_Conveyor_Runtime(IN := TRUE, PT := Duration_Conveyor_Runtime);
        interconnect_Conveyor_Runtime := Timer_Conveyor_Runtime.Q;
    END_ACTION
    ACTION Conveyor_Init_active
        SorterConveyorTowardsStacker := TRUE;
        SorterConveyorTowardsCrane := FALSE;
        Timer_Conveyor_Test(IN := TRUE, PT := Duration_Conveyor_Test);
        interconnect_Conveyor_Test := Timer_Conveyor_Test.Q;
    END_ACTION
    ACTION Start_Conveyor_active_0
        interconnectConveyorTerminationCommand := FALSE;
        SorterConveyorTowardsStacker := FALSE;
        SorterConveyorTowardsCrane := FALSE;
        SorterGreenLampConveyor := FALSE;
        interconnect_Conveyor_Runtime := FALSE;
        interconnect_Conveyor_Test := FALSE;
        Timer_Conveyor_Test(IN := FALSE, PT := TIME#0ms);
        Timer_Conveyor_Runtime(IN := FALSE, PT := TIME#0ms);
        StartVar := FALSE;
        StartCommandConveyor := FALSE;
        IF (SorterStartButton = TRUE) THEN
            interconnectConveyorStartCommand := TRUE;
        END_IF
    END_ACTION
    ACTION Start_Conveyor_active
        IF (SorterStartButton = TRUE) THEN
            SorterGreenLampConveyor := TRUE;
            interconnectConveyorStartCommand := TRUE;
        END_IF
    END_ACTION
    ACTION Green_Lamp_active
        SorterGreenLampConveyor := TRUE;
        interconnectConveyorStartCommand := FALSE;
    END_ACTION
    ACTION Conveyor_Towards_Stacker_active
        SorterConveyorTowardsStacker := TRUE;
        SorterConveyorTowardsCrane := FALSE;
    END_ACTION
    IF (SFCInit OR SFCReset) THEN
        Duration_Conveyor_Runtime := TIME#4500ms;
        Duration_Conveyor_Test := TIME#1000ms;
        SFCInit := FALSE;
        SFCReset := FALSE;
        SorterConveyorTowardsCrane := FALSE;
        SorterConveyorTowardsStacker := FALSE;
        SorterGreenLampConveyor := FALSE;
        SorterLightbarrierCraneInterface := FALSE;
        SorterStartButton := FALSE;
        SorterSwitchManuellAutomatic := FALSE;
        SorterWhiteLampConveyor := FALSE;
        StartCommandConveyor := FALSE;
        StartVar := FALSE;
        Timer_Conveyor_Runtime.ET := UINT#0;
        Timer_Conveyor_Runtime.IN := FALSE;
        Timer_Conveyor_Runtime.PT := UINT#0;
        Timer_Conveyor_Runtime.Q := FALSE;
        Timer_Conveyor_Test.ET := UINT#0;
        Timer_Conveyor_Test.IN := FALSE;
        Timer_Conveyor_Test.PT := UINT#0;
        Timer_Conveyor_Test.Q := FALSE;
        __transit := FALSE;
        _state := STATES_CONVEYOR#INIT;
        interconnectConveyorStartCommand := FALSE;
        interconnectConveyorTerminationCommand := FALSE;
        interconnect_Conveyor_Runtime := FALSE;
        interconnect_Conveyor_Test := FALSE;
    END_IF
    IF NOT (SFCInit OR SFCPause) THEN
        //Running pipeline step: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //End of: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        CASE _state OF 
            STATES_CONVEYOR#Init:
                __transit := FALSE;
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Start_Conveyor;
                END_IF
            
            STATES_CONVEYOR#Start_Conveyor:
                __transit := FALSE;
                Start_Conveyor_active_0();
                IF interconnectConveyorStartCommand THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Green_Lamp;
                END_IF
            
            STATES_CONVEYOR#Green_Lamp:
                __transit := FALSE;
                Green_Lamp_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Conveyor_Init;
                END_IF
            
            STATES_CONVEYOR#Conveyor_Init:
                __transit := FALSE;
                Conveyor_Init_active();
                IF interconnect_Conveyor_Test THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Conveyor_init_2;
                END_IF
            
            STATES_CONVEYOR#Conveyor_init_2:
                __transit := FALSE;
                Conveyor_init_2_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Interstep;
                END_IF
            
            STATES_CONVEYOR#Interstep:
                __transit := FALSE;
                Interstep_active();
                IF StartVar THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Step0;
                END_IF
            
            STATES_CONVEYOR#Step0:
                __transit := FALSE;
                IF SorterLightbarrierCraneInterface THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Conveyor_Towards_Stacker;
                ELSIF NOT SorterLightbarrierCraneInterface THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Conveyor_Stop_Empty_Magazin;
                END_IF
            
            STATES_CONVEYOR#Conveyor_Towards_Stacker:
                __transit := FALSE;
                Conveyor_Towards_Stacker_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Runtime_Conveyor;
                END_IF
            
            STATES_CONVEYOR#Runtime_Conveyor:
                __transit := FALSE;
                Runtime_Conveyor_active();
                IF interconnect_Conveyor_Runtime THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Conveyor_pause;
                END_IF
            
            STATES_CONVEYOR#Conveyor_pause:
                __transit := FALSE;
                Conveyor_pause_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Interstep;
                END_IF
            
            STATES_CONVEYOR#Conveyor_Stop_Empty_Magazin:
                __transit := FALSE;
                Conveyor_Stop_Empty_Magazin_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CONVEYOR#Interstep;
                END_IF
            
                    END_CASE
        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        //Running pipeline step: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

    END_IF
    //End of: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

END_FUNCTION_BLOCK

FUNCTION_BLOCK Crane
    
    VAR_OUTPUT  
        AnalogCranePressure : INT := INT#0;
        CraneLower : BOOL := FALSE;
        CraneTurnClockwise : BOOL := FALSE;
        CraneTurnCounterclockwise : BOOL := FALSE;
        MagazinVacuumOff : BOOL := FALSE;
        MagazinVacuumOn : BOOL := FALSE;
        StartCommandCrane : BOOL := FALSE;
    END_VAR
    
    VAR_INPUT  
        CraneDown : BOOL := FALSE;
        CraneOnConveyor : BOOL := FALSE;
        CraneOnMagazin : BOOL := FALSE;
        CranePositionStamp : BOOL := FALSE;
        CraneSucked : BOOL := FALSE;
        CraneUp : BOOL := FALSE;
        MagazinCapacitiveSensor : BOOL := FALSE;
        MagazinOpticalSensor : BOOL := FALSE;
        SFCReset : BOOL := FALSE;
        SliderMovedOut : BOOL := FALSE;
        SliderNotMovedOut : BOOL := FALSE;
        StampLowered : BOOL := FALSE;
        StampSliderFilled : BOOL := FALSE;
        StampSliderSensorMovedOut : BOOL := FALSE;
        StartButtonMagazin : BOOL := FALSE;
        StartVar : BOOL := FALSE;
        WorkpieceReady : BOOL := FALSE;
    END_VAR
    
    VAR  
        Duration1 : TIME := TIME#1500.0ms;
        SFCInit : BOOL := FALSE;
        TimeDelay_Timer : TON := (Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0);
        TimeDelay_Timer_Duration : TIME := TIME#50.0ms;
        TimeDelay_Timer_interconnect : BOOL := FALSE;
        Timer1 : TON := (Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0);
        actualtime1 : TIME := TIME#;
        interconnect : BOOL := FALSE;
        interconnectCraneStartCommand : BOOL := FALSE;
    END_VAR
    
    VAR  
        SFCPause : BOOL := FALSE;
    END_VAR
    
    VAR  
        __transit : BOOL := FALSE;
        _state : STATES_CRANE := STATES_CRANE#INIT;
    END_VAR
    
    
    ACTION CraneTurnLeft_active
        CraneTurnCounterclockwise := TRUE;
        CraneTurnClockwise := FALSE;
    END_ACTION
    ACTION Crane_Lift_Magazin_Metallic_active_0
        CraneLower := FALSE;
    END_ACTION
    ACTION Crane_Turn_Left_Metallic2_active
        CraneTurnCounterclockwise := TRUE;
        CraneTurnClockwise := FALSE;
    END_ACTION
    ACTION Start_Crane_active
        CraneLower := FALSE;
        MagazinVacuumOff := TRUE;
        MagazinVacuumOn := FALSE;
        CraneTurnCounterclockwise := FALSE;
        CraneTurnClockwise := FALSE;
        AnalogCranePressure := INT#0;
        StartVar := FALSE;
        StartCommandCrane := FALSE;
        IF (StartButtonMagazin = TRUE) THEN
            interconnectCraneStartCommand := TRUE;
        END_IF
    END_ACTION
    ACTION Crane_Turn_Right_From_Stamp_active
        CraneTurnClockwise := TRUE;
        CraneTurnCounterclockwise := FALSE;
    END_ACTION
    ACTION Crane_Lift_At_Stamp_active
        CraneLower := FALSE;
    END_ACTION
    ACTION Suck_At_Stamp_active
        MagazinVacuumOn := TRUE;
        MagazinVacuumOff := FALSE;
    END_ACTION
    ACTION Crane_Go_Up_White_active
        CraneLower := FALSE;
    END_ACTION
    ACTION Crane_Turn_Left_From_Stamp_active
        CraneTurnClockwise := TRUE;
        CraneTurnCounterclockwise := FALSE;
    END_ACTION
    ACTION release_Black_active
        MagazinVacuumOn := FALSE;
        MagazinVacuumOff := TRUE;
    END_ACTION
    ACTION Reset_interconnect_active
        interconnect := FALSE;
        Timer1(IN := FALSE, PT := TIME#1ms);
    END_ACTION
    ACTION Crane_On_Stamp_White_active
        CraneTurnCounterclockwise := FALSE;
        CraneTurnClockwise := FALSE;
        CraneLower := TRUE;
    END_ACTION
    ACTION Turn_Right_active
        CraneTurnClockwise := TRUE;
        CraneTurnCounterclockwise := FALSE;
    END_ACTION
    ACTION Interstep_active
        StartCommandCrane := TRUE;
    END_ACTION
    ACTION CraneLiftConveyor_active
        CraneLower := FALSE;
    END_ACTION
    ACTION Crane_On_Conveyor_Not_Metallica_Black_active
        CraneTurnCounterclockwise := FALSE;
        CraneTurnClockwise := FALSE;
        CraneLower := TRUE;
    END_ACTION
    ACTION Lower_Crane_active
        CraneLower := TRUE;
    END_ACTION
    ACTION Crane_Turn_Left_Metallic_active
        CraneTurnCounterclockwise := TRUE;
        CraneTurnClockwise := FALSE;
    END_ACTION
    ACTION release2_active
        MagazinVacuumOff := TRUE;
        MagazinVacuumOn := FALSE;
    END_ACTION
    ACTION release_active
        MagazinVacuumOff := TRUE;
        MagazinVacuumOn := FALSE;
    END_ACTION
    ACTION Crane_Turn_Left_Back_To_Stamp_active
        CraneTurnCounterclockwise := TRUE;
        CraneTurnClockwise := FALSE;
    END_ACTION
    ACTION Crane_Lift_At_Stamp2_active
        CraneLower := FALSE;
    END_ACTION
    ACTION Turn_Right_Black_active
        CraneTurnClockwise := TRUE;
        CraneTurnCounterclockwise := FALSE;
    END_ACTION
    ACTION Turn_Right_Final_active
        CraneTurnClockwise := TRUE;
        CraneTurnCounterclockwise := FALSE;
        AnalogCranePressure := INT#0;
    END_ACTION
    ACTION Magazin_Stop_active
        CraneTurnClockwise := FALSE;
        CraneTurnCounterClockwise := FALSE;
    END_ACTION
    ACTION Crane_On_Conveyor_Metallic_active
        CraneTurnCounterclockwise := FALSE;
        CraneTurnClockwise := FALSE;
        CraneLower := TRUE;
    END_ACTION
    ACTION release_Workpiece_White_active
        MagazinVacuumOff := TRUE;
        MagazinVacuumOn := FALSE;
    END_ACTION
    ACTION Crane_Turn_Left_White_active
        CraneTurnCounterclockwise := TRUE;
        CraneTurnClockwise := FALSE;
    END_ACTION
    ACTION Crane_On_Conveyor_Metallic_active_0
        CraneTurnCounterclockwise := FALSE;
        CraneTurnClockwise := FALSE;
        CraneLower := TRUE;
    END_ACTION
    ACTION Crane_Lift_Magazin_White_active
        CraneLower := FALSE;
    END_ACTION
    ACTION release_Workpiece_active
        MagazinVacuumOff := TRUE;
        MagazinVacuumOn := FALSE;
    END_ACTION
    ACTION Crane_On_Stamp_Stop_Black_active
        CraneTurnClockwise := FALSE;
        CraneTurnCounterclockwise := FALSE;
    END_ACTION
    ACTION No_Workpiece_ready_active_0
        MagazinVacuumOn := FALSE;
        MagazinVacuumOff := FALSE;
        CraneLower := FALSE;
    END_ACTION
    ACTION TimeDelay_active
        TimeDelay_Timer(IN := TRUE, PT := TimeDelay_Timer_Duration);
        TimeDelay_Timer_interconnect := TimeDelay_Timer.Q;
    END_ACTION
    ACTION Crane_Lift_Conveyor_Black_active
        CraneLower := FALSE;
    END_ACTION
    ACTION Crane_Go_Up_active
        CraneLower := FALSE;
    END_ACTION
    ACTION pause_active
        Timer1(IN := CraneUP, PT := Duration1);
        interconnect := Timer1.Q;
    END_ACTION
    ACTION Crane_Lower_active
        MagazinVacuumOn := TRUE;
        MagazinVacuumOff := FALSE;
        CraneLower := TRUE;
        AnalogCranePressure := INT#0;
    END_ACTION
    ACTION Crane_On_Stamp_Metallic2_active
        CraneTurnCounterclockwise := FALSE;
        CraneTurnClockwise := FALSE;
    END_ACTION
    ACTION Crane_Init_2_active
        CraneLower := FALSE;
    END_ACTION
    ACTION Suck_At_Stamp2_active
        MagazinVacuumOn := TRUE;
        MagazinVacuumOff := FALSE;
    END_ACTION
    ACTION Stamp_Pressure_Profile_Set_White_active
        AnalogCranePressure := INT#6000;
    END_ACTION
    ACTION Crane_On_Stamp_Metallic2_Lower_active
        CraneLower := TRUE;
    END_ACTION
    ACTION CraneOnConveyor_active
        CraneTurnCounterclockwise := FALSE;
        CraneTurnClockwise := FALSE;
        CraneLower := TRUE;
    END_ACTION
    ACTION Stamp_Pressure_Profile_Set_Metallic_active
        AnalogCranePressure := INT#7000;
    END_ACTION
    ACTION Crane_Lift_NOT_Metallic_Black_active
        CraneLower := FALSE;
    END_ACTION
    ACTION CraneLiftMagazin_active
        CraneLower := FALSE;
    END_ACTION
    ACTION Stop_Evernything_active
    END_ACTION
    ACTION Crane_Init_active
        CraneLower := TRUE;
        interconnectCraneStartCommand := FALSE;
        AnalogCranePressure := INT#6000;
    END_ACTION
    ACTION Crane_On_Conveyor_Metallic2_active
        CraneTurnCounterclockwise := FALSE;
        CraneTurnClockwise := FALSE;
        CraneLower := TRUE;
    END_ACTION
    ACTION Magazin_Stop_Final_active
        CraneTurnClockwise := FALSE;
        CraneTurnCounterClockwise := FALSE;
    END_ACTION
    ACTION Crane_Lift_Conveyor2_active
        CraneLower := FALSE;
    END_ACTION
    ACTION Crane_Turn_Left_NOT_Metallic_Black_active
        CraneTurnCounterclockwise := TRUE;
        CraneTurnClockwise := FALSE;
    END_ACTION
    ACTION Magazin_Stop_Black_active
        CraneTurnClockwise := FALSE;
        CraneTurnCounterclockwise := FALSE;
        MagazinVacuumOn := TRUE;
        MagazinVacuumOff := FALSE;
        CraneLower := TRUE;
    END_ACTION
    IF (SFCInit OR SFCReset) THEN
        AnalogCranePressure := INT#0;
        CraneDown := FALSE;
        CraneLower := FALSE;
        CraneOnConveyor := FALSE;
        CraneOnMagazin := FALSE;
        CranePositionStamp := FALSE;
        CraneSucked := FALSE;
        CraneTurnClockwise := FALSE;
        CraneTurnCounterclockwise := FALSE;
        CraneUp := FALSE;
        Duration1 := TIME#1500ms;
        MagazinCapacitiveSensor := FALSE;
        MagazinOpticalSensor := FALSE;
        MagazinVacuumOff := FALSE;
        MagazinVacuumOn := FALSE;
        SFCInit := FALSE;
        SFCReset := FALSE;
        SliderMovedOut := FALSE;
        SliderNotMovedOut := FALSE;
        StampLowered := FALSE;
        StampSliderFilled := FALSE;
        StampSliderSensorMovedOut := FALSE;
        StartButtonMagazin := FALSE;
        StartCommandCrane := FALSE;
        StartVar := FALSE;
        TimeDelay_Timer.ET := UINT#0;
        TimeDelay_Timer.IN := FALSE;
        TimeDelay_Timer.PT := UINT#0;
        TimeDelay_Timer.Q := FALSE;
        TimeDelay_Timer_Duration := TIME#50ms;
        TimeDelay_Timer_interconnect := FALSE;
        Timer1.ET := UINT#0;
        Timer1.IN := FALSE;
        Timer1.PT := UINT#0;
        Timer1.Q := FALSE;
        WorkpieceReady := FALSE;
        __transit := FALSE;
        _state := STATES_CRANE#INIT;
        actualtime1 := TIME#0ms;
        interconnect := FALSE;
        interconnectCraneStartCommand := FALSE;
    END_IF
    IF NOT (SFCInit OR SFCPause) THEN
        //Running pipeline step: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //End of: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        CASE _state OF 
            STATES_CRANE#Init:
                __transit := FALSE;
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Start_Crane;
                END_IF
            
            STATES_CRANE#Start_Crane:
                __transit := FALSE;
                Start_Crane_active();
                IF interconnectCraneStartCommand THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Init;
                END_IF
            
            STATES_CRANE#Crane_Init:
                __transit := FALSE;
                Crane_Init_active();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Init_2;
                END_IF
            
            STATES_CRANE#Crane_Init_2:
                __transit := FALSE;
                Crane_Init_2_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Interstep;
                END_IF
            
            STATES_CRANE#Interstep:
                __transit := FALSE;
                Interstep_active();
                IF StartVar THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Interstep_2;
                END_IF
            
            STATES_CRANE#Interstep_2:
                __transit := FALSE;
                IF SliderMovedOut THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#TimeDelay;
                END_IF
            
            STATES_CRANE#TimeDelay:
                __transit := FALSE;
                TimeDelay_active();
                IF TimeDelay_Timer_interconnect THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Interstep_3;
                END_IF
            
            STATES_CRANE#Interstep_3:
                __transit := FALSE;
                IF WorkpieceReady THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Turn_Right;
                ELSIF NOT WorkpieceReady THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#No_Workpiece_ready;
                END_IF
            
            STATES_CRANE#Turn_Right:
                __transit := FALSE;
                Turn_Right_active();
                IF CraneOnMagazin THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Magazin_Stop;
                END_IF
            
            STATES_CRANE#Magazin_Stop:
                __transit := FALSE;
                Magazin_Stop_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lower;
                END_IF
            
            STATES_CRANE#Crane_Lower:
                __transit := FALSE;
                Crane_Lower_active();
                IF CraneSucked THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Step0;
                END_IF
            
            STATES_CRANE#Step0:
                __transit := FALSE;
                IF (NOT MagazinCapacitiveSensor AND NOT MagazinOpticalSensor) THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_Magazin;
                ELSIF (MagazinCapacitiveSensor AND MagazinOpticalSensor) THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Stamp_Pressure_Profile_Set_Metallic;
                ELSIF (NOT MagazinCapacitiveSensor AND MagazinOpticalSensor) THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Stamp_Pressure_Profile_Set_White;
                ELSIF (MagazinCapacitiveSensor AND MagazinOpticalSensor) THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Stamp_Pressure_Profile_Set_Metallic;
                ELSIF (NOT MagazinCapacitiveSensor AND MagazinOpticalSensor) THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Stamp_Pressure_Profile_Set_White;
                END_IF
            
            STATES_CRANE#Crane_Lift_Magazin:
                __transit := FALSE;
                CraneLiftMagazin_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Turn_Left_NOT_Metallic;
                END_IF
            
            STATES_CRANE#Crane_Turn_Left_NOT_Metallic:
                __transit := FALSE;
                CraneTurnLeft_active();
                IF CraneOnConveyor THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Conveyor;
                END_IF
            
            STATES_CRANE#Crane_On_Conveyor:
                __transit := FALSE;
                CraneOnConveyor_active();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#release;
                END_IF
            
            STATES_CRANE#Stamp_Pressure_Profile_Set_Metallic:
                __transit := FALSE;
                Stamp_Pressure_Profile_Set_Metallic_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_Magazin_Metallic;
                END_IF
            
            STATES_CRANE#Crane_Lift_Magazin_Metallic:
                __transit := FALSE;
                Crane_Lift_Magazin_Metallic_active_0();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Turn_Left_Metallic;
                END_IF
            
            STATES_CRANE#Crane_Turn_Left_Metallic:
                __transit := FALSE;
                Crane_Turn_Left_Metallic_active();
                IF CranePositionStamp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Stamp_Metallic;
                END_IF
            
            STATES_CRANE#Crane_On_Stamp_Metallic:
                __transit := FALSE;
                Crane_On_Conveyor_Metallic_active();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#release_Workpiece;
                END_IF
            
            STATES_CRANE#release_Workpiece:
                __transit := FALSE;
                release_Workpiece_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Go_Up;
                END_IF
            
            STATES_CRANE#Crane_Go_Up:
                __transit := FALSE;
                Crane_Go_Up_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Step3;
                END_IF
            
            STATES_CRANE#Stamp_Pressure_Profile_Set_White:
                __transit := FALSE;
                Stamp_Pressure_Profile_Set_White_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_Magazin_White;
                END_IF
            
            STATES_CRANE#Crane_Lift_Magazin_White:
                __transit := FALSE;
                Crane_Lift_Magazin_White_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Turn_Left_White;
                END_IF
            
            STATES_CRANE#Crane_Turn_Left_White:
                __transit := FALSE;
                Crane_Turn_Left_White_active();
                IF CranePositionStamp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Stamp_White;
                END_IF
            
            STATES_CRANE#Crane_On_Stamp_White:
                __transit := FALSE;
                Crane_On_Stamp_White_active();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#release_Workpiece_White;
                END_IF
            
            STATES_CRANE#release_Workpiece_White:
                __transit := FALSE;
                release_Workpiece_White_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Go_Up_White;
                END_IF
            
            STATES_CRANE#Crane_Go_Up_White:
                __transit := FALSE;
                Crane_Go_Up_White_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Step3;
                END_IF
            
            STATES_CRANE#Step3:
                __transit := FALSE;
                IF WorkpieceReady THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Step2;
                ELSIF NOT WorkpieceReady THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Step4;
                END_IF
            
            STATES_CRANE#Step2:
                __transit := FALSE;
                IF (MagazinCapacitiveSensor OR MagazinOpticalSensor) THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#pause;
                ELSIF (NOT MagazinCapacitiveSensor AND NOT MagazinOpticalSensor) THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Turn_Right_Black;
                END_IF
            
            STATES_CRANE#pause:
                __transit := FALSE;
                pause_active();
                IF interconnect THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Reset_interconnect;
                ELSIF interconnect THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Reset_interconnect;
                END_IF
            
            STATES_CRANE#Turn_Right_Black:
                __transit := FALSE;
                Turn_Right_Black_active();
                IF CraneOnMagazin THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Magazin_Stop_Black;
                END_IF
            
            STATES_CRANE#Magazin_Stop_Black:
                __transit := FALSE;
                Magazin_Stop_Black_active();
                IF CraneSucked THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_NOT_Metallic_Black;
                END_IF
            
            STATES_CRANE#Crane_Lift_NOT_Metallic_Black:
                __transit := FALSE;
                Crane_Lift_NOT_Metallic_Black_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Turn_Left_NOT_Metallic_Black;
                END_IF
            
            STATES_CRANE#Crane_Turn_Left_NOT_Metallic_Black:
                __transit := FALSE;
                Crane_Turn_Left_NOT_Metallic_Black_active();
                IF CraneOnConveyor THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Conveyor_Not_Metallica_Black;
                END_IF
            
            STATES_CRANE#Crane_On_Conveyor_Not_Metallica_Black:
                __transit := FALSE;
                Crane_On_Conveyor_Not_Metallica_Black_active();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#release_Black;
                END_IF
            
            STATES_CRANE#release_Black:
                __transit := FALSE;
                release_Black_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_Conveyor_Black;
                END_IF
            
            STATES_CRANE#Crane_Lift_Conveyor_Black:
                __transit := FALSE;
                Crane_Lift_Conveyor_Black_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Turn_Left_Back_To_Stamp;
                END_IF
            
            STATES_CRANE#Crane_Turn_Left_Back_To_Stamp:
                __transit := FALSE;
                Crane_Turn_Left_Back_To_Stamp_active();
                IF CranePositionStamp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Stamp_Stop_Black;
                END_IF
            
            STATES_CRANE#Crane_On_Stamp_Stop_Black:
                __transit := FALSE;
                Crane_On_Stamp_Stop_Black_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Reset_interconnect;
                ELSIF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Reset_interconnect;
                END_IF
            
            STATES_CRANE#Step4:
                __transit := FALSE;
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Interstep;
                END_IF
            
            STATES_CRANE#Reset_interconnect:
                __transit := FALSE;
                Reset_interconnect_active();
                IF SliderMovedOut THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Lower_Crane;
                END_IF
            
            STATES_CRANE#Lower_Crane:
                __transit := FALSE;
                Lower_Crane_active();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Suck_At_Stamp;
                END_IF
            
            STATES_CRANE#Suck_At_Stamp:
                __transit := FALSE;
                Suck_At_Stamp_active();
                IF CraneSucked THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_At_Stamp;
                END_IF
            
            STATES_CRANE#Crane_Lift_At_Stamp:
                __transit := FALSE;
                Crane_Lift_At_Stamp_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Turn_Left_From_Stamp;
                END_IF
            
            STATES_CRANE#Crane_Turn_Left_From_Stamp:
                __transit := FALSE;
                Crane_Turn_Left_From_Stamp_active();
                IF CraneOnConveyor THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Conveyor_Metallic;
                END_IF
            
            STATES_CRANE#Crane_On_Conveyor_Metallic:
                __transit := FALSE;
                Crane_On_Conveyor_Metallic_active_0();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#release;
                END_IF
            
            STATES_CRANE#release:
                __transit := FALSE;
                release_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_Conveyor;
                END_IF
            
            STATES_CRANE#Crane_Lift_Conveyor:
                __transit := FALSE;
                CraneLiftConveyor_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Interstep;
                END_IF
            
            STATES_CRANE#No_Workpiece_ready:
                __transit := FALSE;
                No_Workpiece_ready_active_0();
                IF StampSliderFilled THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Turn_Left_Metallic2;
                ELSIF NOT StampSliderFilled THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Turn_Right_Final;
                END_IF
            
            STATES_CRANE#Crane_Turn_Left_Metallic2:
                __transit := FALSE;
                Crane_Turn_Left_Metallic2_active();
                IF CranePositionStamp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Stamp_Metallic2;
                END_IF
            
            STATES_CRANE#Crane_On_Stamp_Metallic2:
                __transit := FALSE;
                Crane_On_Stamp_Metallic2_active();
                IF StampLowered THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Interstep_4;
                END_IF
            
            STATES_CRANE#Interstep_4:
                __transit := FALSE;
                IF StampSliderSensorMovedOut THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Stamp_Metallic2_Lower;
                END_IF
            
            STATES_CRANE#Crane_On_Stamp_Metallic2_Lower:
                __transit := FALSE;
                Crane_On_Stamp_Metallic2_Lower_active();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Suck_At_Stamp2;
                END_IF
            
            STATES_CRANE#Suck_At_Stamp2:
                __transit := FALSE;
                Suck_At_Stamp2_active();
                IF CraneSucked THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_At_Stamp2;
                END_IF
            
            STATES_CRANE#Crane_Lift_At_Stamp2:
                __transit := FALSE;
                Crane_Lift_At_Stamp2_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Turn_Right_From_Stamp;
                END_IF
            
            STATES_CRANE#Crane_Turn_Right_From_Stamp:
                __transit := FALSE;
                Crane_Turn_Right_From_Stamp_active();
                IF CraneOnConveyor THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_On_Conveyor_Metallic2;
                END_IF
            
            STATES_CRANE#Crane_On_Conveyor_Metallic2:
                __transit := FALSE;
                Crane_On_Conveyor_Metallic2_active();
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#release2;
                END_IF
            
            STATES_CRANE#release2:
                __transit := FALSE;
                release2_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Crane_Lift_Conveyor2;
                END_IF
            
            STATES_CRANE#Crane_Lift_Conveyor2:
                __transit := FALSE;
                Crane_Lift_Conveyor2_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Interstep;
                ELSIF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Interstep;
                END_IF
            
            STATES_CRANE#Turn_Right_Final:
                __transit := FALSE;
                Turn_Right_Final_active();
                IF CraneOnMagazin THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Magazin_Stop_Final;
                END_IF
            
            STATES_CRANE#Magazin_Stop_Final:
                __transit := FALSE;
                Magazin_Stop_Final_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_CRANE#Start_Crane;
                END_IF
            
                    END_CASE
        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        //Running pipeline step: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

    END_IF
    //End of: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

END_FUNCTION_BLOCK

FUNCTION_BLOCK Magazin
    
    VAR_INPUT  
        CraneDown : BOOL := FALSE;
        CraneOnConveyor : BOOL := FALSE;
        CraneOnMagazin : BOOL := FALSE;
        CraneSucked : BOOL := FALSE;
        CraneUp : BOOL := FALSE;
        SFCReset : BOOL := FALSE;
        SliderMovedOut : BOOL := FALSE;
        SliderNotMovedOut : BOOL := FALSE;
        StartButtonMagazin : BOOL := FALSE;
        StartVar : BOOL := FALSE;
        WorkpieceReady : BOOL := FALSE;
    END_VAR
    
    VAR_OUTPUT  
        CraneLower : BOOL := FALSE;
        CraneTurnClockwise : BOOL := FALSE;
        CraneTurnCounterclockwise : BOOL := FALSE;
        MagazinGreenLamp : BOOL := FALSE;
        MagazinSlider : BOOL := FALSE;
        MagazinVacuumOff : BOOL := FALSE;
        MagazinVacuumOn : BOOL := FALSE;
        MagazinWhiteLamp : BOOL := FALSE;
        StartCommandMagazin : BOOL := FALSE;
    END_VAR
    
    VAR  
        SFCInit : BOOL := FALSE;
        interconnectMagazinStartCommand : BOOL := FALSE;
    END_VAR
    
    VAR  
        SFCPause : BOOL := FALSE;
    END_VAR
    
    VAR  
        __transit : BOOL := FALSE;
        _state : STATES_MAGAZIN := STATES_MAGAZIN#INIT;
    END_VAR
    
    
    ACTION Magazin_Init_active
        MagazinSlider := TRUE;
    END_ACTION
    ACTION Magazin_Init_2_active
        MagazinSlider := FALSE;
    END_ACTION
    ACTION SliderMoveBack_active
        IF ((SliderMovedOut = TRUE) AND (SliderNotMovedOut = FALSE)) THEN
            MagazinSlider := FALSE;
        END_IF
    END_ACTION
    ACTION convey_active
        IF SliderNotMovedOut THEN
            MagazinSlider := TRUE;
        END_IF
    END_ACTION
    ACTION Interstep_active
        StartCommandMagazin := TRUE;
    END_ACTION
    ACTION Start_Magazin_active
        MagazinSlider := FALSE;
        MagazinGreenLamp := FALSE;
        StartVar := FALSE;
        StartCommandMagazin := FALSE;
        IF (StartButtonMagazin = TRUE) THEN
            interconnectMagazinStartCommand := TRUE;
        END_IF
    END_ACTION
    ACTION Green_Lamp_active
        MagazinGreenLamp := TRUE;
        interconnectMagazinStartCommand := FALSE;
    END_ACTION
    IF (SFCInit OR SFCReset) THEN
        CraneDown := FALSE;
        CraneLower := FALSE;
        CraneOnConveyor := FALSE;
        CraneOnMagazin := FALSE;
        CraneSucked := FALSE;
        CraneTurnClockwise := FALSE;
        CraneTurnCounterclockwise := FALSE;
        CraneUp := FALSE;
        MagazinGreenLamp := FALSE;
        MagazinSlider := FALSE;
        MagazinVacuumOff := FALSE;
        MagazinVacuumOn := FALSE;
        MagazinWhiteLamp := FALSE;
        SFCInit := FALSE;
        SFCReset := FALSE;
        SliderMovedOut := FALSE;
        SliderNotMovedOut := FALSE;
        StartButtonMagazin := FALSE;
        StartCommandMagazin := FALSE;
        StartVar := FALSE;
        WorkpieceReady := FALSE;
        __transit := FALSE;
        _state := STATES_MAGAZIN#INIT;
        interconnectMagazinStartCommand := FALSE;
    END_IF
    IF NOT (SFCInit OR SFCPause) THEN
        //Running pipeline step: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //End of: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        CASE _state OF 
            STATES_MAGAZIN#Init:
                __transit := FALSE;
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Start_Magazin;
                END_IF
            
            STATES_MAGAZIN#Start_Magazin:
                __transit := FALSE;
                Start_Magazin_active();
                IF interconnectMagazinStartCommand THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Green_Lamp;
                END_IF
            
            STATES_MAGAZIN#Green_Lamp:
                __transit := FALSE;
                Green_Lamp_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Magazin_Init;
                END_IF
            
            STATES_MAGAZIN#Magazin_Init:
                __transit := FALSE;
                Magazin_Init_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Magazin_Init_2;
                END_IF
            
            STATES_MAGAZIN#Magazin_Init_2:
                __transit := FALSE;
                Magazin_Init_2_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Interstep;
                END_IF
            
            STATES_MAGAZIN#Interstep:
                __transit := FALSE;
                Interstep_active();
                IF StartVar THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#convey;
                END_IF
            
            STATES_MAGAZIN#convey:
                __transit := FALSE;
                convey_active();
                IF CraneOnMagazin THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Step0;
                END_IF
            
            STATES_MAGAZIN#Step0:
                __transit := FALSE;
                IF CraneDown THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Slider_Move_Back;
                END_IF
            
            STATES_MAGAZIN#Slider_Move_Back:
                __transit := FALSE;
                SliderMoveBack_active();
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Step1;
                END_IF
            
            STATES_MAGAZIN#Step1:
                __transit := FALSE;
                IF CraneOnConveyor THEN
                    __transit := TRUE;
                    _state := STATES_MAGAZIN#Interstep;
                END_IF
            
                    END_CASE
        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        //Running pipeline step: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

    END_IF
    //End of: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

END_FUNCTION_BLOCK

FUNCTION_BLOCK Pusher
    
    VAR  
        Duration1 : TIME := TIME#320.0ms;
        Duration2 : TIME := TIME#390.0ms;
        Duration3 : TIME := TIME#200.0ms;
        SFCInit : BOOL := FALSE;
        Timer1 : TON := (Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0);
        Timer2 : TON := (Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0);
        Timer3 : TON := (Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0);
        enum : INT := INT#0;
        interconnect : BOOL := FALSE;
        interconnect2 : BOOL := FALSE;
        interconnect3 : BOOL := FALSE;
    END_VAR
    
    VAR_OUTPUT  
        PusherY1 : BOOL := FALSE;
        PusherY2 : BOOL := FALSE;
    END_VAR
    
    VAR  
        SFCPause : BOOL := FALSE;
    END_VAR
    
    VAR_INPUT  
        SFCReset : BOOL := FALSE;
        SorterCapacitiveSensorPusher1 : BOOL := FALSE;
        SorterCapacitiveSensorPusher2 : BOOL := FALSE;
        SorterLightbarrierCraneInterface : BOOL := FALSE;
        SorterLightnessSensorPusher1 : BOOL := FALSE;
        SorterLightnessSensorPusher2 : BOOL := FALSE;
        SorterLightnessSensorPusher3 : BOOL := FALSE;
        SorterLightnesssensorCraneInterfaceInverse : BOOL := FALSE;
        SorterPusher1MovedIn : BOOL := FALSE;
        SorterPusher1MovedOut : BOOL := FALSE;
        SorterPusher2MovedIn : BOOL := FALSE;
        SorterPusher2MovedOut : BOOL := FALSE;
        SorterStartButton : BOOL := FALSE;
        StartVar : BOOL := FALSE;
    END_VAR
    
    VAR  
        __transit : BOOL := FALSE;
        _state : STATES_PUSHER := STATES_PUSHER#INIT;
    END_VAR
    
    
    ACTION PusherY2_Move_Out_active
        IF ((SorterPusher2MovedOut = FALSE) AND (SorterPusher2MovedIn = TRUE)) THEN
            PusherY2 := TRUE;
        END_IF
    END_ACTION
    ACTION First_Slide_Timer_active
        Timer1(IN := TRUE, PT := Duration1);
        interconnect := Timer1.Q;
    END_ACTION
    ACTION Wait_Black_active
        IF ((NOT SorterLightnessSensorPusher2 AND NOT SorterCapacitiveSensorPusher2) = TRUE) THEN
            Timer3(IN := (NOT SorterLightnessSensorPusher2 AND NOT SorterCapacitiveSensorPusher2), PT := Duration3);
            interconnect3 := Timer3.Q;
        END_IF
    END_ACTION
    ACTION Enumeration_active
        enum := (enum + INT#1);
    END_ACTION
    ACTION Reset_interconnect3_active
        interconnect3 := FALSE;
        Timer3(IN := FALSE, PT := TIME#0ms);
    END_ACTION
    ACTION Wait_Y2_active
        IF (PusherY2 = TRUE) THEN
            Timer3(IN := PusherY2, PT := Duration3);
            interconnect3 := Timer3.Q;
        END_IF
    END_ACTION
    ACTION Second_Slide_Timer_active
        Timer2(IN := TRUE, PT := Duration2);
        interconnect2 := Timer2.Q;
    END_ACTION
    ACTION Reset_interconnect2_active
        interconnect2 := FALSE;
        interconnect3 := FALSE;
        Timer2(IN := FALSE, PT := TIME#0ms);
        Timer3(IN := FALSE, PT := TIME#0ms);
    END_ACTION
    ACTION PusherY1_Move_Out_active
        IF ((SorterPusher1MovedOut = FALSE) AND (SorterPusher1MovedIn = TRUE)) THEN
            PusherY1 := TRUE;
        END_IF
    END_ACTION
    ACTION PusherY2_Move_In_active
        IF ((SorterPusher2MovedOut = TRUE) AND (SorterPusher2MovedIn = FALSE)) THEN
            PusherY2 := FALSE;
        END_IF
    END_ACTION
    ACTION Interstep_active
        PusherY1 := FALSE;
        PusherY2 := FALSE;
        interconnect := FALSE;
        interconnect2 := FALSE;
        interconnect3 := FALSE;
        StartVar := FALSE;
    END_ACTION
    ACTION Wait_Y1_active
        IF (PusherY1 = TRUE) THEN
            Timer3(IN := PusherY1, PT := Duration3);
            interconnect3 := Timer3.Q;
        END_IF
    END_ACTION
    ACTION Reset_interconnect_active
        interconnect := FALSE;
        interconnect3 := FALSE;
        Timer1(IN := FALSE, PT := TIME#0ms);
        Timer3(IN := FALSE, PT := TIME#0ms);
    END_ACTION
    ACTION PusherY1_Move_In_active
        IF ((SorterPusher1MovedOut = TRUE) AND (SorterPusher1MovedIn = FALSE)) THEN
            PusherY1 := FALSE;
        END_IF
    END_ACTION
    IF (SFCInit OR SFCReset) THEN
        Duration1 := TIME#320ms;
        Duration2 := TIME#390ms;
        Duration3 := TIME#200ms;
        PusherY1 := FALSE;
        PusherY2 := FALSE;
        SFCInit := FALSE;
        SFCReset := FALSE;
        SorterCapacitiveSensorPusher1 := FALSE;
        SorterCapacitiveSensorPusher2 := FALSE;
        SorterLightbarrierCraneInterface := FALSE;
        SorterLightnessSensorPusher1 := FALSE;
        SorterLightnessSensorPusher2 := FALSE;
        SorterLightnessSensorPusher3 := FALSE;
        SorterLightnesssensorCraneInterfaceInverse := FALSE;
        SorterPusher1MovedIn := FALSE;
        SorterPusher1MovedOut := FALSE;
        SorterPusher2MovedIn := FALSE;
        SorterPusher2MovedOut := FALSE;
        SorterStartButton := FALSE;
        StartVar := FALSE;
        Timer1.ET := UINT#0;
        Timer1.IN := FALSE;
        Timer1.PT := UINT#0;
        Timer1.Q := FALSE;
        Timer2.ET := UINT#0;
        Timer2.IN := FALSE;
        Timer2.PT := UINT#0;
        Timer2.Q := FALSE;
        Timer3.ET := UINT#0;
        Timer3.IN := FALSE;
        Timer3.PT := UINT#0;
        Timer3.Q := FALSE;
        __transit := FALSE;
        _state := STATES_PUSHER#INIT;
        enum := INT#0;
        interconnect := FALSE;
        interconnect2 := FALSE;
        interconnect3 := FALSE;
    END_IF
    IF NOT (SFCInit OR SFCPause) THEN
        //Running pipeline step: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //End of: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        CASE _state OF 
            STATES_PUSHER#Init:
                __transit := FALSE;
                IF StartVar THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Interstep;
                END_IF
            
            STATES_PUSHER#Interstep:
                __transit := FALSE;
                Interstep_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Interstep_2;
                END_IF
            
            STATES_PUSHER#Interstep_2:
                __transit := FALSE;
                IF NOT SorterLightnesssensorCraneInterfaceInverse THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Check_For_Black_By_Using_Inverse_Sensor;
                ELSIF (SorterLightnessSensorPusher1 AND NOT SorterCapacitiveSensorPusher1) THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#First_Slide_only_white_workpieces;
                ELSIF (SorterLightnessSensorPusher1 AND SorterCapacitiveSensorPusher1) THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Second_Slide_only_metal_workpieces;
                END_IF
            
            STATES_PUSHER#Check_For_Black_By_Using_Inverse_Sensor:
                __transit := FALSE;
                IF (NOT SorterLightnessSensorPusher1 AND NOT SorterCapacitiveSensorPusher1) THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Third_Slide_only_black_workpieces;
                END_IF
            
            STATES_PUSHER#Third_Slide_only_black_workpieces:
                __transit := FALSE;
                IF (NOT SorterLightnessSensorPusher2 AND NOT SorterCapacitiveSensorPusher2) THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Wait_Black;
                END_IF
            
            STATES_PUSHER#Wait_Black:
                __transit := FALSE;
                Wait_Black_active();
                IF interconnect3 THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Reset_interconnect3;
                END_IF
            
            STATES_PUSHER#Reset_interconnect3:
                __transit := FALSE;
                Reset_interconnect3_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Interstep_2;
                END_IF
            
            STATES_PUSHER#First_Slide_only_white_workpieces:
                __transit := FALSE;
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#First_Slide_Timer;
                END_IF
            
            STATES_PUSHER#First_Slide_Timer:
                __transit := FALSE;
                First_Slide_Timer_active();
                IF interconnect THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#PusherY1_Move_Out;
                END_IF
            
            STATES_PUSHER#PusherY1_Move_Out:
                __transit := FALSE;
                PusherY1_Move_Out_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Wait_Y1;
                END_IF
            
            STATES_PUSHER#Wait_Y1:
                __transit := FALSE;
                Wait_Y1_active();
                IF interconnect3 THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#PusherY1_Move_In;
                END_IF
            
            STATES_PUSHER#PusherY1_Move_In:
                __transit := FALSE;
                PusherY1_Move_In_active();
                IF SorterPusher1MovedIn THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Reset_interconnect;
                END_IF
            
            STATES_PUSHER#Reset_interconnect:
                __transit := FALSE;
                Reset_interconnect_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Interstep_2;
                END_IF
            
            STATES_PUSHER#Second_Slide_only_metal_workpieces:
                __transit := FALSE;
                IF (SorterLightnessSensorPusher2 AND SorterCapacitiveSensorPusher2) THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Second_Test_For_Metal;
                END_IF
            
            STATES_PUSHER#Second_Test_For_Metal:
                __transit := FALSE;
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Second_Slide_Timer;
                END_IF
            
            STATES_PUSHER#Second_Slide_Timer:
                __transit := FALSE;
                Second_Slide_Timer_active();
                IF interconnect2 THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#PusherY2_Move_Out;
                END_IF
            
            STATES_PUSHER#PusherY2_Move_Out:
                __transit := FALSE;
                PusherY2_Move_Out_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Wait_Y2;
                END_IF
            
            STATES_PUSHER#Wait_Y2:
                __transit := FALSE;
                Wait_Y2_active();
                IF interconnect3 THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#PusherY2_Move_In;
                END_IF
            
            STATES_PUSHER#PusherY2_Move_In:
                __transit := FALSE;
                PusherY2_Move_In_active();
                IF SorterPusher2MovedIn THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Reset_interconnect2;
                END_IF
            
            STATES_PUSHER#Reset_interconnect2:
                __transit := FALSE;
                Reset_interconnect2_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_PUSHER#Interstep_2;
                END_IF
            
                    END_CASE
        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        //Running pipeline step: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

    END_IF
    //End of: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

END_FUNCTION_BLOCK

FUNCTION_BLOCK Stamp
    
    VAR_INPUT  
        CraneDown : BOOL := FALSE;
        CraneOnConveyor : BOOL := FALSE;
        CranePositionStamp : BOOL := FALSE;
        CraneSucked : BOOL := FALSE;
        CraneUp : BOOL := FALSE;
        SFCReset : BOOL := FALSE;
        StampLowered : BOOL := FALSE;
        StampSliderFilled : BOOL := FALSE;
        StampSliderSensorMovedIn : BOOL := FALSE;
        StampSliderSensorMovedOut : BOOL := FALSE;
        StampStartButton : BOOL := FALSE;
        StampUp : BOOL := FALSE;
        StartVar : BOOL := FALSE;
    END_VAR
    
    VAR  
        Duration : TIME := TIME#500.0ms;
        SFCInit : BOOL := FALSE;
        Timer : TON := (Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0);
        interconnect : BOOL := FALSE;
        interconnectStampStartCommand : BOOL := FALSE;
    END_VAR
    
    VAR  
        SFCPause : BOOL := FALSE;
    END_VAR
    
    VAR_OUTPUT  
        StampGreenLamp : BOOL := FALSE;
        StampPressure : BOOL := FALSE;
        StampPusher : BOOL := FALSE;
        StampSliderMovedIn : BOOL := FALSE;
        StampSliderMovedOut : BOOL := FALSE;
        StampWhiteLamp : BOOL := FALSE;
        StartCommandStamp : BOOL := FALSE;
    END_VAR
    
    VAR  
        __transit : BOOL := FALSE;
        _state : STATES_STAMP := STATES_STAMP#INIT;
    END_VAR
    
    
    ACTION StampSliderForward_active
        StampPusher := FALSE;
        StampSliderMovedOut := TRUE;
        IF ((StampLowered = FALSE) AND (StampUp = TRUE)) THEN
            interconnect := FALSE;
        END_IF
        Timer(IN := FALSE, PT := TIME#1ms);
    END_ACTION
    ACTION StampSliderBack_active
        StampSliderMovedIn := TRUE;
        StampSliderMovedOut := FALSE;
    END_ACTION
    ACTION Start_Stamp_active
        StampSliderMovedOut := FALSE;
        StampSliderMovedIn := FALSE;
        StampPusher := FALSE;
        StampGreenLamp := FALSE;
        StampPressure := FALSE;
        StartCommandStamp := FALSE;
        IF (StampStartButton = TRUE) THEN
            interconnectStampStartCommand := TRUE;
        END_IF
    END_ACTION
    ACTION Step1_active
        Timer(IN := StampLowered, PT := TIME#0ms);
        interconnect := Timer.Q;
    END_ACTION
    ACTION Stamp_Init_2_active
        StampSliderMovedIn := FALSE;
        StampSliderMovedOut := TRUE;
    END_ACTION
    ACTION Green_Lamp_active
        StampGreenLamp := TRUE;
        interconnectStampStartCommand := FALSE;
    END_ACTION
    ACTION Stamp_Init_4_active
        StampPusher := FALSE;
    END_ACTION
    ACTION Stamp_Init_1_active
        StampSliderMovedIn := TRUE;
        StampSliderMovedOut := FALSE;
    END_ACTION
    ACTION StampProcess_active
        StampSliderMovedIn := FALSE;
        StampPusher := TRUE;
    END_ACTION
    ACTION Stamp_Init_3_active
        StampPusher := TRUE;
    END_ACTION
    ACTION Interstep_active
        StartCommandStamp := TRUE;
    END_ACTION
    IF (SFCInit OR SFCReset) THEN
        CraneDown := FALSE;
        CraneOnConveyor := FALSE;
        CranePositionStamp := FALSE;
        CraneSucked := FALSE;
        CraneUp := FALSE;
        Duration := TIME#500ms;
        SFCInit := FALSE;
        SFCReset := FALSE;
        StampGreenLamp := FALSE;
        StampLowered := FALSE;
        StampPressure := FALSE;
        StampPusher := FALSE;
        StampSliderFilled := FALSE;
        StampSliderMovedIn := FALSE;
        StampSliderMovedOut := FALSE;
        StampSliderSensorMovedIn := FALSE;
        StampSliderSensorMovedOut := FALSE;
        StampStartButton := FALSE;
        StampUp := FALSE;
        StampWhiteLamp := FALSE;
        StartCommandStamp := FALSE;
        StartVar := FALSE;
        Timer.ET := UINT#0;
        Timer.IN := FALSE;
        Timer.PT := UINT#0;
        Timer.Q := FALSE;
        __transit := FALSE;
        _state := STATES_STAMP#INIT;
        interconnect := FALSE;
        interconnectStampStartCommand := FALSE;
    END_IF
    IF NOT (SFCInit OR SFCPause) THEN
        //Running pipeline step: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //End of: edu.kit.iti.formal.automation.st.IntroduceStateEnumVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$IntroduceTransitVariable

        //Running pipeline step: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        CASE _state OF 
            STATES_STAMP#Init:
                __transit := FALSE;
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Start_Stamp;
                END_IF
            
            STATES_STAMP#Start_Stamp:
                __transit := FALSE;
                Start_Stamp_active();
                IF interconnectStampStartCommand THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Green_Lamp;
                END_IF
            
            STATES_STAMP#Green_Lamp:
                __transit := FALSE;
                Green_Lamp_active();
                IF TRUE THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Stamp_Init_1;
                END_IF
            
            STATES_STAMP#Stamp_Init_1:
                __transit := FALSE;
                Stamp_Init_1_active();
                IF StampSliderSensorMovedIn THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Stamp_Init_2;
                END_IF
            
            STATES_STAMP#Stamp_Init_2:
                __transit := FALSE;
                Stamp_Init_2_active();
                IF StampSliderSensorMovedOut THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Stamp_Init_3;
                END_IF
            
            STATES_STAMP#Stamp_Init_3:
                __transit := FALSE;
                Stamp_Init_3_active();
                IF StampLowered THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Stamp_Init_4;
                END_IF
            
            STATES_STAMP#Stamp_Init_4:
                __transit := FALSE;
                Stamp_Init_4_active();
                IF StampUp THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Interstep;
                END_IF
            
            STATES_STAMP#Interstep:
                __transit := FALSE;
                Interstep_active();
                IF StartVar THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Interstep_2;
                END_IF
            
            STATES_STAMP#Interstep_2:
                __transit := FALSE;
                IF StampSliderFilled THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Step0;
                END_IF
            
            STATES_STAMP#Step0:
                __transit := FALSE;
                IF CraneUp THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#StampSliderBack;
                END_IF
            
            STATES_STAMP#StampSliderBack:
                __transit := FALSE;
                StampSliderBack_active();
                IF StampSliderSensorMovedIn THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#StampProcess;
                END_IF
            
            STATES_STAMP#StampProcess:
                __transit := FALSE;
                StampProcess_active();
                IF StampLowered THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Step1;
                END_IF
            
            STATES_STAMP#Step1:
                __transit := FALSE;
                Step1_active();
                IF interconnect THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#StampSliderForward;
                END_IF
            
            STATES_STAMP#StampSliderForward:
                __transit := FALSE;
                StampSliderForward_active();
                IF StampSliderMovedOut THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Step2;
                END_IF
            
            STATES_STAMP#Step2:
                __transit := FALSE;
                IF (CraneOnConveyor AND NOT StampSliderFilled) THEN
                    __transit := TRUE;
                    _state := STATES_STAMP#Interstep;
                END_IF
            
                    END_CASE
        //End of: edu.kit.iti.formal.automation.st.TranslationSfcToStOld$TheBigStateCase

        //Running pipeline step: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

    END_IF
    //End of: edu.kit.iti.formal.automation.st.SfcFlagIntroduction

END_FUNCTION_BLOCK

PROGRAM Main
    VAR_OUTPUT  
        Actuator_AnalogCranePressure : INT := INT#0;
        Actuator_CraneLower : BOOL := FALSE;
        Actuator_CraneTurnClockwise : BOOL := FALSE;
        Actuator_CraneTurnCounterclockwise : BOOL := FALSE;
        Actuator_MagazinGreenLamp : BOOL := FALSE;
        Actuator_MagazinSlider : BOOL := FALSE;
        Actuator_MagazinVacuumOff : BOOL := FALSE;
        Actuator_MagazinVacuumOn : BOOL := FALSE;
        Actuator_MagazinWhiteLamp : BOOL := FALSE;
        Actuator_PusherY1 : BOOL := FALSE;
        Actuator_PusherY2 : BOOL := FALSE;
        Actuator_SomeActuator : BOOL := FALSE;
        Actuator_SorterConveyorTowardsCrane : BOOL := FALSE;
        Actuator_SorterConveyorTowardsStacker : BOOL := FALSE;
        Actuator_SorterGreenLampConveyor : BOOL := FALSE;
        Actuator_SorterWhiteLampConveyor : BOOL := FALSE;
        Actuator_StampGreenLamp : BOOL := FALSE;
        Actuator_StampPusher : BOOL := FALSE;
        Actuator_StampSliderMovedIn : BOOL := FALSE;
        Actuator_StampSliderMovedOut : BOOL := FALSE;
        Actuator_StampWhiteLamp : BOOL := FALSE;
    END_VAR
    
    VAR  
        Conveyor : Conveyor := (SFCReset:=FALSE, Timer_Conveyor_Runtime:=(Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0), SorterStartButton:=FALSE, interconnect_Conveyor_Test:=FALSE, SorterConveyorTowardsCrane:=FALSE, interconnectConveyorStartCommand:=FALSE, SFCInit:=FALSE, interconnectConveyorTerminationCommand:=FALSE, SorterConveyorTowardsStacker:=FALSE, interconnect_Conveyor_Runtime:=FALSE, Timer_Conveyor_Test:=(Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0), SorterLightbarrierCraneInterface:=FALSE, SorterSwitchManuellAutomatic:=FALSE, StartVar:=FALSE, SorterGreenLampConveyor:=FALSE, StartCommandConveyor:=FALSE, Duration_Conveyor_Test:=TIME#1000.0ms, Duration_Conveyor_Runtime:=TIME#4500.0ms, SorterWhiteLampConveyor:=FALSE);
        Crane : Crane := (SliderMovedOut:=FALSE, CraneTurnCounterclockwise:=FALSE, WorkpieceReady:=FALSE, StampLowered:=FALSE, Duration1:=TIME#1500.0ms, StampSliderSensorMovedOut:=FALSE, TimeDelay_Timer_interconnect:=FALSE, CraneOnConveyor:=FALSE, MagazinOpticalSensor:=FALSE, CranePositionStamp:=FALSE, StartVar:=FALSE, StartButtonMagazin:=FALSE, CraneOnMagazin:=FALSE, actualtime1:=TIME#, AnalogCranePressure:=INT#0, SFCReset:=FALSE, MagazinVacuumOff:=FALSE, CraneSucked:=FALSE, MagazinVacuumOn:=FALSE, interconnectCraneStartCommand:=FALSE, SFCInit:=FALSE, StartCommandCrane:=FALSE, TimeDelay_Timer_Duration:=TIME#50.0ms, interconnect:=FALSE, StampSliderFilled:=FALSE, CraneTurnClockwise:=FALSE, CraneUp:=FALSE, MagazinCapacitiveSensor:=FALSE, CraneLower:=FALSE, SliderNotMovedOut:=FALSE, CraneDown:=FALSE, TimeDelay_Timer:=(Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0), Timer1:=(Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0));
        Mag : Magazin := (SliderMovedOut:=FALSE, MagazinGreenLamp:=FALSE, interconnectMagazinStartCommand:=FALSE, SFCReset:=FALSE, CraneTurnCounterclockwise:=FALSE, MagazinVacuumOff:=FALSE, WorkpieceReady:=FALSE, CraneSucked:=FALSE, MagazinSlider:=FALSE, MagazinVacuumOn:=FALSE, MagazinWhiteLamp:=FALSE, SFCInit:=FALSE, StartCommandMagazin:=FALSE, CraneOnConveyor:=FALSE, CraneTurnClockwise:=FALSE, CraneUp:=FALSE, StartVar:=FALSE, CraneLower:=FALSE, SliderNotMovedOut:=FALSE, StartButtonMagazin:=FALSE, CraneOnMagazin:=FALSE, CraneDown:=FALSE);
        Pusher : Pusher := (SorterLightnessSensorPusher2:=FALSE, SorterPusher1MovedOut:=FALSE, SorterStartButton:=FALSE, SorterLightnessSensorPusher1:=FALSE, Duration3:=TIME#200.0ms, Duration2:=TIME#390.0ms, Duration1:=TIME#320.0ms, SorterPusher1MovedIn:=FALSE, SorterPusher2MovedIn:=FALSE, SorterLightbarrierCraneInterface:=FALSE, StartVar:=FALSE, SorterLightnessSensorPusher3:=FALSE, PusherY2:=FALSE, PusherY1:=FALSE, SFCReset:=FALSE, SorterCapacitiveSensorPusher2:=FALSE, SorterCapacitiveSensorPusher1:=FALSE, interconnect3:=FALSE, interconnect2:=FALSE, SFCInit:=FALSE, interconnect:=FALSE, enum:=INT#0, SorterLightnesssensorCraneInterfaceInverse:=FALSE, SorterPusher2MovedOut:=FALSE, Timer2:=(Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0), Timer1:=(Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0), Timer3:=(Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0));
        Stamp : Stamp := (StampLowered:=FALSE, StampSliderSensorMovedOut:=FALSE, interconnectStampStartCommand:=FALSE, CraneOnConveyor:=FALSE, CranePositionStamp:=FALSE, StampSliderMovedOut:=FALSE, StartVar:=FALSE, StampPusher:=FALSE, StampWhiteLamp:=FALSE, StampPressure:=FALSE, SFCReset:=FALSE, StampGreenLamp:=FALSE, CraneSucked:=FALSE, Duration:=TIME#500.0ms, SFCInit:=FALSE, StampStartButton:=FALSE, StampSliderSensorMovedIn:=FALSE, interconnect:=FALSE, StampSliderFilled:=FALSE, CraneUp:=FALSE, StampSliderMovedIn:=FALSE, Timer:=(Q:=FALSE, PT:=UINT#0, IN:=FALSE, ET:=UINT#0), StartCommandStamp:=FALSE, CraneDown:=FALSE, StampUp:=FALSE);
    END_VAR
    
    VAR_INPUT  
        Sensor_CraneDown : BOOL := FALSE;
        Sensor_CraneOnConveyor : BOOL := FALSE;
        Sensor_CraneOnMagazin : BOOL := FALSE;
        Sensor_CranePosition : BOOL := FALSE;
        Sensor_CranePositionStamp : BOOL := FALSE;
        Sensor_CraneSucked : BOOL := FALSE;
        Sensor_CraneUp : BOOL := FALSE;
        Sensor_MagazinCapacitiveSensor : BOOL := FALSE;
        Sensor_MagazinEmergencyStop : BOOL := FALSE;
        Sensor_MagazinOpticalSensor : BOOL := FALSE;
        Sensor_MagazinSwitchManuellAutomatic : BOOL := FALSE;
        Sensor_SliderMovedOut : BOOL := FALSE;
        Sensor_SliderNotMovedOut : BOOL := FALSE;
        Sensor_SorterCapacitiveSensorPusher1 : BOOL := FALSE;
        Sensor_SorterCapacitiveSensorPusher2 : BOOL := FALSE;
        Sensor_SorterEmergencyStop : BOOL := FALSE;
        Sensor_SorterLightbarrierCraneInterface : BOOL := FALSE;
        Sensor_SorterLightnessSensorPusher1 : BOOL := FALSE;
        Sensor_SorterLightnessSensorPusher2 : BOOL := FALSE;
        Sensor_SorterLightnessSensorPusher3 : BOOL := FALSE;
        Sensor_SorterLightnesssensorCraneInterfaceInverse : BOOL := FALSE;
        Sensor_SorterPusher1MovedIn : BOOL := FALSE;
        Sensor_SorterPusher1MovedOut : BOOL := FALSE;
        Sensor_SorterPusher2MovedIn : BOOL := FALSE;
        Sensor_SorterPusher2MovedOut : BOOL := FALSE;
        Sensor_SorterStartButton : BOOL := FALSE;
        Sensor_SorterSwitchManuellAutomatic : BOOL := FALSE;
        Sensor_StampEmergencyStop : BOOL := FALSE;
        Sensor_StampLowered : BOOL := FALSE;
        Sensor_StampSliderFilled : BOOL := FALSE;
        Sensor_StampSliderSensorMovedIn : BOOL := FALSE;
        Sensor_StampSliderSensorMovedOut : BOOL := FALSE;
        Sensor_StampStartButton : BOOL := FALSE;
        Sensor_StampSwitchManuellAutomatic : BOOL := FALSE;
        Sensor_StampUp : BOOL := FALSE;
        Sensor_StartButtonMagazin : BOOL := FALSE;
        Sensor_WorkpieceReady : BOOL := FALSE;
    END_VAR
    
    
    Mag.SliderNotMovedOut := Sensor_SliderNotMovedOut;
    Mag.SliderMovedOut := Sensor_SliderMovedOut;
    Mag.CraneOnMagazin := Sensor_CraneOnMagazin;
    Mag.CraneDown := Sensor_CraneDown;
    Mag.CraneUp := Sensor_CraneUp;
    Mag.CraneOnConveyor := Sensor_CraneOnConveyor;
    Mag.WorkpieceReady := Sensor_WorkpieceReady;
    Mag.StartButtonMagazin := Sensor_StartButtonMagazin;
    Actuator_MagazinSlider := Mag.MagazinSlider;
    Actuator_MagazinGreenLamp := Mag.MagazinGreenLamp;
    Crane.CraneUp := Sensor_CraneUp;
    Crane.CraneOnConveyor := Sensor_CraneOnConveyor;
    Crane.CraneDown := Sensor_CraneDown;
    Crane.CraneSucked := Sensor_CraneSucked;
    Crane.CraneOnMagazin := Sensor_CraneOnMagazin;
    Crane.MagazinCapacitiveSensor := Sensor_MagazinCapacitiveSensor;
    Crane.CranePositionStamp := Sensor_CranePositionStamp;
    Crane.SliderMovedOut := Sensor_SliderMovedOut;
    Crane.WorkpieceReady := Sensor_WorkpieceReady;
    Crane.MagazinOpticalSensor := Sensor_MagazinOpticalSensor;
    Crane.StampSliderFilled := Sensor_StampSliderFilled;
    Crane.StampSliderSensorMovedOut := Sensor_StampSliderSensorMovedOut;
    Crane.StampLowered := Sensor_StampLowered;
    Crane.StartButtonMagazin := Sensor_StartButtonMagazin;
    Actuator_CraneTurnCounterclockwise := Crane.CraneTurnCounterclockwise;
    Actuator_CraneTurnClockwise := Crane.CraneTurnClockwise;
    Actuator_CraneLower := Crane.CraneLower;
    Actuator_MagazinVacuumOff := Crane.MagazinVacuumOff;
    Actuator_MagazinVacuumOn := Crane.MagazinVacuumOn;
    Actuator_AnalogCranePressure := Crane.AnalogCranePressure;
    Stamp.StampSliderSensorMovedOut := Sensor_StampSliderSensorMovedOut;
    Stamp.StampSliderSensorMovedIn := Sensor_StampSliderSensorMovedIn;
    Stamp.StampSliderFilled := Sensor_StampSliderFilled;
    Stamp.StampUp := Sensor_StampUp;
    Stamp.StampLowered := Sensor_StampLowered;
    Stamp.CraneDown := Sensor_CraneDown;
    Stamp.CraneUp := Sensor_CraneUp;
    Stamp.CraneSucked := Sensor_CraneSucked;
    Stamp.CranePositionStamp := Sensor_CranePositionStamp;
    Stamp.CraneOnConveyor := Sensor_CraneOnConveyor;
    Stamp.StampStartButton := Sensor_StampStartButton;
    Actuator_StampSliderMovedOut := Stamp.StampSliderMovedOut;
    Actuator_StampSliderMovedIn := Stamp.StampSliderMovedIn;
    Actuator_StampWhiteLamp := Stamp.StampWhiteLamp;
    Actuator_StampPusher := Stamp.StampPusher;
    Actuator_StampGreenLamp := Stamp.StampGreenLamp;
    Conveyor.SorterStartButton := Sensor_SorterStartButton;
    Conveyor.SorterSwitchManuellAutomatic := Sensor_SorterSwitchManuellAutomatic;
    Conveyor.SorterLightbarrierCraneInterface := Sensor_SorterLightbarrierCraneInterface;
    Actuator_SorterConveyorTowardsStacker := Conveyor.SorterConveyorTowardsStacker;
    Actuator_SorterConveyorTowardsCrane := Conveyor.SorterConveyorTowardsCrane;
    Actuator_SorterGreenLampConveyor := Conveyor.SorterGreenLampConveyor;
    Actuator_SorterWhiteLampConveyor := Conveyor.SorterWhiteLampConveyor;
    Pusher.SorterLightnesssensorCraneInterfaceInverse := Sensor_SorterLightnesssensorCraneInterfaceInverse;
    Pusher.SorterLightbarrierCraneInterface := Sensor_SorterLightbarrierCraneInterface;
    Pusher.SorterCapacitiveSensorPusher1 := Sensor_SorterCapacitiveSensorPusher1;
    Pusher.SorterLightnessSensorPusher1 := Sensor_SorterLightnessSensorPusher1;
    Pusher.SorterCapacitiveSensorPusher2 := Sensor_SorterCapacitiveSensorPusher2;
    Pusher.SorterLightnessSensorPusher2 := Sensor_SorterLightnessSensorPusher2;
    Pusher.SorterLightnessSensorPusher3 := Sensor_SorterLightnessSensorPusher3;
    Pusher.SorterPusher1MovedOut := Sensor_SorterPusher1MovedOut;
    Pusher.SorterPusher1MovedIn := Sensor_SorterPusher1MovedIn;
    Pusher.SorterPusher2MovedOut := Sensor_SorterPusher2MovedOut;
    Pusher.SorterPusher2MovedIn := Sensor_SorterPusher2MovedIn;
    Pusher.SorterStartButton := Sensor_SorterStartButton;
    Actuator_PusherY1 := Pusher.PusherY1;
    Actuator_PusherY2 := Pusher.PusherY2;
    IF ((Sensor_SorterEmergencyStop AND Sensor_StampEmergencyStop) AND Sensor_MagazinEmergencyStop) THEN
        Mag();
        Crane();
        Stamp();
        Conveyor();
        Pusher();
        IF ((Actuator_SorterGreenLampConveyor AND Actuator_MagazinGreenLamp) AND Actuator_StampGreenLamp) THEN
            IF (((Stamp.StartCommandStamp AND Crane.StartCommandCrane) AND Conveyor.StartCommandConveyor) AND Mag.StartCommandMagazin) THEN
                Crane.StartVar := TRUE;
                Conveyor.StartVar := TRUE;
                Mag.StartVar := TRUE;
                Pusher.StartVar := TRUE;
                Stamp.StartVar := TRUE;
            END_IF
        END_IF
        Crane.SFCReset := FALSE;
        Conveyor.SFCReset := FALSE;
        Mag.SFCReset := FALSE;
        Pusher.SFCReset := FALSE;
        Stamp.SFCReset := FALSE;
    ELSIF ((NOT Sensor_SorterEmergencyStop OR NOT Sensor_StampEmergencyStop) OR NOT Sensor_MagazinEmergencyStop) THEN
        Actuator_MagazinSlider := FALSE;
        Actuator_CraneLower := FALSE;
        Actuator_MagazinVacuumOn := FALSE;
        Actuator_MagazinVacuumOff := TRUE;
        Actuator_MagazinGreenLamp := FALSE;
        Actuator_CraneTurnCounterclockwise := FALSE;
        Actuator_CraneTurnClockwise := FALSE;
        Actuator_SorterConveyorTowardsStacker := FALSE;
        Actuator_SorterConveyorTowardsCrane := FALSE;
        Actuator_SorterGreenLampConveyor := FALSE;
        Actuator_PusherY1 := FALSE;
        Actuator_PusherY2 := FALSE;
        Actuator_StampSliderMovedOut := TRUE;
        Actuator_StampSliderMovedIn := FALSE;
        Actuator_StampGreenLamp := FALSE;
        Actuator_StampPusher := FALSE;
        Actuator_AnalogCranePressure := INT#0;
        Crane.SFCReset := TRUE;
        Conveyor.SFCReset := TRUE;
        Mag.SFCReset := TRUE;
        Pusher.SFCReset := TRUE;
        Stamp.SFCReset := TRUE;
        Crane.StartVar := FALSE;
        Conveyor.StartVar := FALSE;
        Mag.StartVar := FALSE;
        Pusher.StartVar := FALSE;
        Stamp.StartVar := FALSE;
    END_IF
END_PROGRAM
FUNCTION_BLOCK CTD
    
    VAR_INPUT  
        CD : BOOL := FALSE;
        LD : BOOL := FALSE;
        PV : INT := INT#0;
    END_VAR
    
    VAR_OUTPUT  
        CV : INT := INT#0;
        Q : BOOL := FALSE;
    END_VAR
    
    
    IF LD THEN
        CV := PV;
    ELSIF (CU AND (CV > INT#0)) THEN
        CV := (CV - INT#1);
    END_IF
    Q := (CV <= INT#0);
END_FUNCTION_BLOCK

FUNCTION_BLOCK CTU
    
    VAR_INPUT  
        CU : BOOL := FALSE;
        PV : INT := INT#0;
        R : BOOL := FALSE;
    END_VAR
    
    VAR_OUTPUT  
        CV : INT := INT#0;
        Q : BOOL := FALSE;
    END_VAR
    
    
    IF R THEN
        CV := INT#0;
    ELSIF (CU AND (CV < PV)) THEN
        CV := (CV + INT#1);
    END_IF
    Q := (CV >= PV);
END_FUNCTION_BLOCK

FUNCTION_BLOCK R_TRIG
    
    VAR_INPUT  
        CLK : BOOL := FALSE;
    END_VAR
    
    VAR  
        M : BOOL := FALSE;
    END_VAR
    
    VAR_OUTPUT  
        Q : BOOL := FALSE;
    END_VAR
    
    
    Q := (CLK AND NOT M);
    M := CLK;
END_FUNCTION_BLOCK

FUNCTION_BLOCK F_TRIG
    
    VAR_INPUT  
        CLK : BOOL := FALSE;
    END_VAR
    
    VAR  
        M : BOOL := TRUE;
    END_VAR
    
    VAR_OUTPUT  
        Q : BOOL := FALSE;
    END_VAR
    
    
    Q := (NOT CLK AND NOT M);
    M := NOT CLK;
END_FUNCTION_BLOCK

FUNCTION SEL : ANY
    
    VAR_INPUT  
        G : BOOL := FALSE;
        a : ANY;
        b : ANY;
    END_VAR
    
    VAR_OUTPUT  
        SEL : ANY;
    END_VAR
    
    IF G THEN
        SEL := a;
    ELSE
        SEL := b;
    END_IF
END_FUNCTION

FUNCTION MAX : ANY_INT
    
    VAR_OUTPUT  
        MAX : ANY_INT;
    END_VAR
    
    VAR_INPUT  
        in0 : ANY_INT;
        in1 : ANY_INT;
    END_VAR
    
    MAX := sel((in0 >= in1), in0, in1);
END_FUNCTION

FUNCTION MIN : ANY_INT
    
    VAR_OUTPUT  
        MIN : ANY_INT;
    END_VAR
    
    VAR_INPUT  
        in0 : ANY_INT;
        in1 : ANY_INT;
    END_VAR
    
    MIN := sel((in0 <= in1), in0, in1);
END_FUNCTION

FUNCTION LIMIT : INT
    
    VAR_OUTPUT  
        LIMIT : INT := INT#0;
    END_VAR
    
    VAR_INPUT  
        in : ANY_INT;
        max : ANY_INT;
        min : ANY_INT;
    END_VAR
    
    LIMIT := MAX(min, MIN(in, max));
END_FUNCTION

FUNCTION ERROR : ANY
    
    VAR_OUTPUT  
        ERROR : ANY;
    END_VAR
    
    VAR  
        msg : STRING := WSTRING#"";
    END_VAR
    
END_FUNCTION

FUNCTION SMV : ANY
    
    VAR_OUTPUT  
        SMV : ANY;
    END_VAR
    
    VAR_INPUT  
        code : STRING := WSTRING#"";
    END_VAR
    
END_FUNCTION

FUNCTION_BLOCK TON
    
    VAR_OUTPUT  
        ET : UINT := UINT#0;
        Q : BOOL := FALSE;
    END_VAR
    
    VAR_INPUT  
        IN : BOOL := FALSE;
        PT : UINT := UINT#0;
    END_VAR
    
    
    IF IN THEN
        Q := (ET = UINT#0);
        IF (ET > UINT#0) THEN
            ET := (ET - UINT#1);
        ELSE
            ET := UINT#0;
        END_IF
    ELSE
        Q := FALSE;
        ET := PT;
    END_IF
END_FUNCTION_BLOCK

TYPE SFC_STEPS: STRUCT
    
        T :TIME
        X :BOOL
        _T :TIME
        _X :BOOLEND_STRUCT;
    
END_TYPE

TYPE 
    STATES_CONVEYOR : (Init, Start_Conveyor, Green_Lamp, Conveyor_Init, Conveyor_init_2, Interstep, Step0, Conveyor_Towards_Stacker, Runtime_Conveyor, Conveyor_pause, Conveyor_Stop_Empty_Magazin);
    STATES_CRANE : (Init, Start_Crane, Crane_Init, Crane_Init_2, Interstep, Interstep_2, TimeDelay, Interstep_3, Turn_Right, Magazin_Stop, Crane_Lower, Step0, Crane_Lift_Magazin, Crane_Turn_Left_NOT_Metallic, Crane_On_Conveyor, Stamp_Pressure_Profile_Set_Metallic, Crane_Lift_Magazin_Metallic, Crane_Turn_Left_Metallic, Crane_On_Stamp_Metallic, release_Workpiece, Crane_Go_Up, Stamp_Pressure_Profile_Set_White, Crane_Lift_Magazin_White, Crane_Turn_Left_White, Crane_On_Stamp_White, release_Workpiece_White, Crane_Go_Up_White, Step3, Step2, pause, Turn_Right_Black, Magazin_Stop_Black, Crane_Lift_NOT_Metallic_Black, Crane_Turn_Left_NOT_Metallic_Black, Crane_On_Conveyor_Not_Metallica_Black, release_Black, Crane_Lift_Conveyor_Black, Crane_Turn_Left_Back_To_Stamp, Crane_On_Stamp_Stop_Black, Step4, Reset_interconnect, Lower_Crane, Suck_At_Stamp, Crane_Lift_At_Stamp, Crane_Turn_Left_From_Stamp, Crane_On_Conveyor_Metallic, release, Crane_Lift_Conveyor, No_Workpiece_ready, Crane_Turn_Left_Metallic2, Crane_On_Stamp_Metallic2, Interstep_4, Crane_On_Stamp_Metallic2_Lower, Suck_At_Stamp2, Crane_Lift_At_Stamp2, Crane_Turn_Right_From_Stamp, Crane_On_Conveyor_Metallic2, release2, Crane_Lift_Conveyor2, Turn_Right_Final, Magazin_Stop_Final);
    STATES_MAGAZIN : (Init, Start_Magazin, Green_Lamp, Magazin_Init, Magazin_Init_2, Interstep, convey, Step0, Slider_Move_Back, Step1);
    STATES_PUSHER : (Init, Interstep, Interstep_2, Check_For_Black_By_Using_Inverse_Sensor, Third_Slide_only_black_workpieces, Wait_Black, Reset_interconnect3, First_Slide_only_white_workpieces, First_Slide_Timer, PusherY1_Move_Out, Wait_Y1, PusherY1_Move_In, Reset_interconnect, Second_Slide_only_metal_workpieces, Second_Test_For_Metal, Second_Slide_Timer, PusherY2_Move_Out, Wait_Y2, PusherY2_Move_In, Reset_interconnect2);
    STATES_STAMP : (Init, Start_Stamp, Green_Lamp, Stamp_Init_1, Stamp_Init_2, Stamp_Init_3, Stamp_Init_4, Interstep, Interstep_2, Step0, StampSliderBack, StampProcess, Step1, StampSliderForward, Step2);
END_TYPE


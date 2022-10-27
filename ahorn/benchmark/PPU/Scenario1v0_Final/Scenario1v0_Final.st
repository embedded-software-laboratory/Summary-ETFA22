PROGRAM Main

VAR  Actuator_CraneLower : BOOL; END_VAR
VAR  Actuator_CraneTurnClockwise : BOOL; END_VAR
VAR  Actuator_CraneTurnCounterclockwise : BOOL; END_VAR
VAR  Actuator_MagazinGreenLamp : BOOL; END_VAR
VAR  Actuator_MagazinSlider : BOOL; END_VAR
VAR  Actuator_MagazinVacuumOff : BOOL; END_VAR
VAR  Actuator_MagazinVacuumOn : BOOL; END_VAR
VAR  Actuator_MagazinWhiteLamp : BOOL; END_VAR
VAR  Crane : Crane; END_VAR
VAR  Mag : Magazin; END_VAR
VAR  Sensor_CraneDown : BOOL; END_VAR
VAR  Sensor_CraneOnConveyor : BOOL; END_VAR
VAR  Sensor_CraneOnMagazin : BOOL; END_VAR
VAR  Sensor_CranePosition : BOOL; END_VAR
VAR  Sensor_CraneSucked : BOOL; END_VAR
VAR  Sensor_CraneUp : BOOL; END_VAR
VAR  Sensor_MagazinEmergencyStop : BOOL; END_VAR
VAR  Sensor_MagazinSwitchManuellAutomatic : BOOL; END_VAR
VAR  Sensor_SliderMovedOut : BOOL; END_VAR
VAR  Sensor_SliderNotMovedOut : BOOL; END_VAR
VAR  Sensor_StartButtonMagazin : BOOL; END_VAR
VAR  Sensor_WorkpieceReady : BOOL; END_VAR
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
Crane.WorkpieceReady := Sensor_WorkpieceReady;
Crane.CraneUp := Sensor_CraneUp;
Crane.CraneOnConveyor := Sensor_CraneOnConveyor;
Crane.CraneDown := Sensor_CraneDown;
Crane.CraneSucked := Sensor_CraneSucked;
Crane.CraneOnMagazin := Sensor_CraneOnMagazin;
Crane.SliderMovedOut := Sensor_SliderMovedOut;
Crane.StartButtonMagazin := Sensor_StartButtonMagazin;
Actuator_CraneTurnCounterclockwise := Crane.CraneTurnCounterclockwise;
Actuator_CraneTurnClockwise := Crane.CraneTurnClockwise;
Actuator_CraneLower := Crane.CraneLower;
Actuator_MagazinVacuumOff := Crane.MagazinVacuumOff;
Actuator_MagazinVacuumOn := Crane.MagazinVacuumOn;
IF Sensor_MagazinEmergencyStop THEN
    Mag();
    Crane();
    IF Actuator_MagazinGreenLamp THEN
        IF (Crane.StartCommandCrane AND Mag.StartCommandMagazin) THEN
            Crane.StartVar := TRUE;
            Mag.StartVar := TRUE;
        END_IF;
    END_IF;
    Crane.SFCReset := FALSE;
    Mag.SFCReset := FALSE;
ELSIF NOT Sensor_MagazinEmergencyStop THEN
    Actuator_MagazinSlider := FALSE;
    Actuator_CraneLower := FALSE;
    Actuator_MagazinVacuumOn := FALSE;
    Actuator_MagazinVacuumOff := TRUE;
    Actuator_MagazinGreenLamp := FALSE;
    Actuator_CraneTurnCounterclockwise := FALSE;
    Actuator_CraneTurnClockwise := FALSE;
    Crane.SFCReset := TRUE;
    Mag.SFCReset := TRUE;
    Crane.StartVar := FALSE;
    Mag.StartVar := FALSE;
END_IF;
END_PROGRAM

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

FUNCTION_BLOCK Magazin
    VAR_INPUT  CraneDown : BOOL; END_VAR
    VAR_INPUT  CraneOnConveyor : BOOL; END_VAR
    VAR_INPUT  CraneOnMagazin : BOOL; END_VAR
    VAR_INPUT  CraneSucked : BOOL; END_VAR
    VAR_INPUT  CraneUp : BOOL; END_VAR
    VAR_OUTPUT  MagazinGreenLamp : BOOL; END_VAR
    VAR_OUTPUT  MagazinSlider : BOOL; END_VAR
    VAR  SFCInit : BOOL; END_VAR
    VAR_INPUT  SFCReset : BOOL; END_VAR
    VAR_INPUT  SliderMovedOut : BOOL; END_VAR
    VAR_INPUT  SliderNotMovedOut : BOOL; END_VAR
    VAR_INPUT  StartButtonMagazin : BOOL; END_VAR
    VAR_OUTPUT  StartCommandMagazin : BOOL; END_VAR
    VAR_INPUT  StartVar : BOOL; END_VAR
    VAR_INPUT  WorkpieceReady : BOOL; END_VAR
    VAR  State : Magazin_states_t; END_VAR
    VAR  Transit : BOOL; END_VAR
    VAR  interconnectMagazinStartCommand : BOOL; END_VAR

    CASE State OF
        Magazin_states_t#Green_Lamp:
            Transit := FALSE;
            MagazinGreenLamp := TRUE;
            interconnectMagazinStartCommand := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Magazin_states_t#Magazin_Init;
            END_IF;

        Magazin_states_t#Init:
            Transit := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Magazin_states_t#Start_Magazin;
            END_IF;

        Magazin_states_t#Interstep:
            Transit := FALSE;
            StartCommandMagazin := TRUE;
            IF StartVar THEN
                Transit := TRUE;
                State := Magazin_states_t#convey;
            END_IF;

        Magazin_states_t#Magazin_Init:
            Transit := FALSE;
            MagazinSlider := TRUE;
            IF TRUE THEN
                Transit := TRUE;
                State := Magazin_states_t#Magazin_Init_2;
            END_IF;

        Magazin_states_t#Magazin_Init_2:
            Transit := FALSE;
            MagazinSlider := FALSE;
            IF TRUE THEN
                Transit := TRUE;
                State := Magazin_states_t#Interstep;
            END_IF;

        Magazin_states_t#Slider_Move_Back:
            Transit := FALSE;
            IF ((SliderMovedOut = TRUE) AND (SliderNotMovedOut = FALSE)) THEN
                MagazinSlider := FALSE;
            END_IF;
            IF CraneUp THEN
                Transit := TRUE;
                State := Magazin_states_t#Step1;
            END_IF;

        Magazin_states_t#Start_Magazin:
            Transit := FALSE;
            MagazinSlider := FALSE;
            MagazinGreenLamp := FALSE;
            StartVar := FALSE;
            StartCommandMagazin := FALSE;
            IF (StartButtonMagazin = TRUE) THEN
                interconnectMagazinStartCommand := TRUE;
            END_IF;
            IF interconnectMagazinStartCommand THEN
                Transit := TRUE;
                State := Magazin_states_t#Green_Lamp;
            END_IF;

        Magazin_states_t#Step0:
            Transit := FALSE;
            IF CraneDown THEN
                Transit := TRUE;
                State := Magazin_states_t#Slider_Move_Back;
            END_IF;

        Magazin_states_t#Step1:
            Transit := FALSE;
            IF CraneOnConveyor THEN
                Transit := TRUE;
                State := Magazin_states_t#Interstep;
            END_IF;

        Magazin_states_t#convey:
            Transit := FALSE;
            IF SliderNotMovedOut THEN
                MagazinSlider := TRUE;
            END_IF;
            IF CraneOnMagazin THEN
                Transit := TRUE;
                State := Magazin_states_t#Step0;
            END_IF;

            END_CASE;
END_FUNCTION_BLOCK

TYPE
    Magazin_states_t : (Green_Lamp , Init , Interstep , Magazin_Init , Magazin_Init_2 , Slider_Move_Back , Start_Magazin , Step0 , Step1 , convey);
    Crane_states_t : (Crane_Init , Crane_Init_2 , Crane_Lift_Conveyor , Crane_Lift_Magazine , Crane_On_Conveyor , Crane_Stop , Crane_Turn_Left , Init , Interstep , Interstep_2 , Interstep_Check_Workpiece , Magazin_Stop , Start_Crane , TimeDelay , Turn_Right , release);
END_TYPE

FUNCTION_BLOCK TON
VAR_INPUT
  IN : BOOL;
  PT : TIME;
END_VAR
VAR
  running : BOOL;
END_VAR
VAR_TEMP
    timeout : BOOL;
END_VAR
VAR_OUTPUT
  Q : BOOL;
  ET : TIME;
END_VAR
  timeout := NONDETERMINISTIC_BOOL();
  IF NOT IN THEN
    Q := FALSE;
    running := FALSE;
  ELSIF NOT running AND NOT Q THEN
    running := TRUE;
  ELSIF running AND NOT Q THEN
    Q := timeout;
    running := NOT Q;
  END_IF;

  ET := NONDETERMINISTIC_TIME();
END_FUNCTION_BLOCK


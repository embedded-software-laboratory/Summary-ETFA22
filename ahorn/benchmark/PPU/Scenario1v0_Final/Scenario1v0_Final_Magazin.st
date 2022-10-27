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


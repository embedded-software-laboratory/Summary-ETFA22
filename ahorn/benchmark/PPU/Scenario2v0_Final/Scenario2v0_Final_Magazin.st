FUNCTION_BLOCK Magazin
    VAR_INPUT  CraneDown : BOOL; END_VAR (*Irwxp*)
    VAR_OUTPUT  CraneLower : BOOL; END_VAR (*Orwxp*)
    VAR_INPUT  CraneOnConveyor : BOOL; END_VAR (*Irwxp*)
    VAR_INPUT  CraneOnMagazin : BOOL; END_VAR (*Irwxp*)
    VAR_INPUT  CraneSucked : BOOL; END_VAR (*Irwxp*)
    VAR_OUTPUT  CraneTurnClockwise : BOOL; END_VAR (*Orwxp*)
    VAR_OUTPUT  CraneTurnCounterclockwise : BOOL; END_VAR (*Orwxp*)
    VAR_INPUT  CraneUp : BOOL; END_VAR (*Irwxp*)
    VAR_OUTPUT  MagazinGreenLamp : BOOL; END_VAR (*Orwxp*)
    VAR_OUTPUT  MagazinSlider : BOOL; END_VAR (*Orwxp*)
    VAR_OUTPUT  MagazinVacuumOff : BOOL; END_VAR (*Orwxp*)
    VAR_OUTPUT  MagazinVacuumOn : BOOL; END_VAR (*Orwxp*)
    VAR_OUTPUT  MagazinWhiteLamp : BOOL; END_VAR (*Orwxp*)
    VAR  SFCInit : BOOL; END_VAR (*Lrwxp*)
    VAR_INPUT  SFCReset : BOOL; END_VAR (*Irwxp*)
    VAR_INPUT  SliderMovedOut : BOOL; END_VAR (*Irwxp*)
    VAR_INPUT  SliderNotMovedOut : BOOL; END_VAR (*Irwxp*)
    VAR_INPUT  StartButtonMagazin : BOOL; END_VAR (*Irwxp*)
    VAR_OUTPUT  StartCommandMagazin : BOOL; END_VAR (*Orwxp*)
    VAR_INPUT  StartVar : BOOL; END_VAR (*Irwxp*)
    VAR_INPUT  WorkpieceReady : BOOL; END_VAR (*Irwxp*)
    VAR  State : Magazin_states_t; END_VAR (*Lrwxp*)
    VAR  Transit : BOOL; END_VAR (*Lrwxp*)
    VAR  interconnectMagazinStartCommand : BOOL; END_VAR (*Lrwxp*)
    
    CASE State OF 
        Magazin_states_t#Green_Lamp:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            MagazinGreenLamp := TRUE;
            interconnectMagazinStartCommand := FALSE;
            (* end(onActive) *)
            (* begin(transition) *)
            IF TRUE THEN
                Transit := TRUE;
                State := Magazin_states_t#Magazin_Init;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#Init:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            (* end(onActive) *)
            (* begin(transition) *)
            IF TRUE THEN
                Transit := TRUE;
                State := Magazin_states_t#Start_Magazin;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#Interstep:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            StartCommandMagazin := TRUE;
            (* end(onActive) *)
            (* begin(transition) *)
            IF StartVar THEN
                Transit := TRUE;
                State := Magazin_states_t#convey;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#Magazin_Init:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            MagazinSlider := TRUE;
            (* end(onActive) *)
            (* begin(transition) *)
            IF TRUE THEN
                Transit := TRUE;
                State := Magazin_states_t#Magazin_Init_2;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#Magazin_Init_2:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            MagazinSlider := FALSE;
            (* end(onActive) *)
            (* begin(transition) *)
            IF TRUE THEN
                Transit := TRUE;
                State := Magazin_states_t#Interstep;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#Slider_Move_Back:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            IF ((SliderMovedOut = TRUE) AND (SliderNotMovedOut = FALSE)) THEN
                MagazinSlider := FALSE;
            END_IF;
            (* end(onActive) *)
            (* begin(transition) *)
            IF CraneUp THEN
                Transit := TRUE;
                State := Magazin_states_t#Step1;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#Start_Magazin:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            MagazinSlider := FALSE;
            MagazinGreenLamp := FALSE;
            StartVar := FALSE;
            StartCommandMagazin := FALSE;
            IF (StartButtonMagazin = TRUE) THEN
                interconnectMagazinStartCommand := TRUE;
            END_IF;
            (* end(onActive) *)
            (* begin(transition) *)
            IF interconnectMagazinStartCommand THEN
                Transit := TRUE;
                State := Magazin_states_t#Green_Lamp;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#Step0:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            (* end(onActive) *)
            (* begin(transition) *)
            IF CraneDown THEN
                Transit := TRUE;
                State := Magazin_states_t#Slider_Move_Back;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#Step1:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            (* end(onActive) *)
            (* begin(transition) *)
            IF CraneOnConveyor THEN
                Transit := TRUE;
                State := Magazin_states_t#Interstep;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
        Magazin_states_t#convey:
            (* begin(State) *)
            (* begin(onEntry) *)
            Transit := FALSE;
            (* end(onEntry) *)
            (* begin(onActive) *)
            IF SliderNotMovedOut THEN
                MagazinSlider := TRUE;
            END_IF;
            (* end(onActive) *)
            (* begin(transition) *)
            IF CraneOnMagazin THEN
                Transit := TRUE;
                State := Magazin_states_t#Step0;
            END_IF;
            (* end(transition) *)
            (* begin(onExit) *)
            (* end(onExit) *)
            (* end(State) *)
        
            END_CASE;
END_FUNCTION_BLOCK


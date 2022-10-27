#!/bin/sh

set -e

EXECUTABLE_FOLDER="./bin"
CYCLE_BOUND=5
BENCHMARK_FOLDER="./benchmark/PLCopen_safety"
TIEMOUT=60

function main() {
    if [[ "$1" == "0" ]]; then
    printf "# CSE vs CSE + Summarization\n\n"
        echo "--- SFAntivalent.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFAntivalent.st

        echo ""

        echo "--- SFAntivalent.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFAntivalent.st

        echo "\n###########################################\n"

        echo "--- SFEDM.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEDM.st

        echo ""

        echo "--- SFEDM.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEDM.st

        echo "\n###########################################\n"

        echo "--- SFEmergencyStop.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEmergencyStop.st

        echo ""

        echo "--- SFEmergencyStop.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEmergencyStop.st

        echo "\n###########################################\n"

        echo "--- SFEnableSwitch.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEnableSwitch.st

        echo ""

        echo "--- SFEnableSwitch.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEnableSwitch.st

        echo "\n###########################################\n"

        echo "--- SFEquivalent.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEquivalent.st

        echo ""

        echo "--- SFEquivalent.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEquivalent.st

        echo "\n###########################################\n"

        echo "--- SFESPE.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFESPE.st

        echo ""

        echo "--- SFESPE.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFESPE.st

        echo "\n###########################################\n"

        echo "--- SFGuardLocking.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardLocking.st

        echo ""

        echo "--- SFGuardLocking.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardLocking.st

        echo "\n###########################################\n"

        echo "--- SFGuardMonitoring.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardMonitoring.st

        echo ""

        echo "--- SFGuardMonitoring.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardMonitoring.st

        echo "\n###########################################\n"

        echo "--- SFModeSelector.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFModeSelector.st

        echo ""

        echo "--- SFModeSelector.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFModeSelector.st

        echo "\n###########################################\n"

        echo "--- SFMutingSeq.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFMutingSeq.st

        echo ""

        echo "--- SFMutingSeq.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFMutingSeq.st

        echo "\n###########################################\n"

        echo "--- SFOutControl.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFOutControl.st

        echo ""

        echo "--- SFOutControl.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFOutControl.st

        echo "\n###########################################\n"

        echo "--- SFSafeStop.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafeStop.st

        echo ""

        echo "--- SFSafeStop.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafeStop.st

        echo "\n###########################################\n"

        echo "--- SFSafelyLimitSpeed.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafelyLimitSpeed.st

        echo ""

        echo "--- SFSafelyLimitSpeed.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafelyLimitSpeed.st

        echo "\n###########################################\n"

        echo "--- SFSafetyRequest.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafetyRequest.st

        echo ""

        echo "--- SFSafetyRequest.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafetyRequest.st

        echo "\n###########################################\n"

        echo "--- SFTestableSafetySensor.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTestableSafetySensor.st

        echo ""

        echo "--- SFTestableSafetySensor.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTestableSafetySensor.st

        echo "\n###########################################\n"

        echo "--- SFTwoHandControlTypeII.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeII.st

        echo ""

        echo "--- SFTwoHandControlTypeII.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeII.st

        echo "\n###########################################\n"

        echo "--- SFTwoHandControlTypeIII.st w/o Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --cse --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeIII.st

        echo ""

        echo "--- SFTwoHandControlTypeIII.st + Summarization ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeIII.st
    elif [[ "$1" == "1" ]]; then
        printf "# CSE + Summarization + Concolic w/ and w/o Merge (and TO)\n\n"

        echo "--- SFAntivalent.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFAntivalent.st

        echo ""

        echo "--- SFAntivalent.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFAntivalent.st

        echo "\n###########################################\n"

        echo "--- SFEDM.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFEDM.st

        echo ""

        echo "--- SFEDM.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEDM.st

        echo "\n###########################################\n"

        echo "--- SFEmergencyStop.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFEmergencyStop.st

        echo ""

        echo "--- SFEmergencyStop.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEmergencyStop.st

        echo "\n###########################################\n"

        echo "--- SFEnableSwitch.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFEnableSwitch.st

        echo ""

        echo "--- SFEnableSwitch.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEnableSwitch.st

        echo "\n###########################################\n"

        echo "--- SFEquivalent.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFEquivalent.st

        echo ""

        echo "--- SFEquivalent.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFEquivalent.st

        echo "\n###########################################\n"

        echo "--- SFESPE.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFESPE.st

        echo ""

        echo "--- SFESPE.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFESPE.st

        echo "\n###########################################\n"

        echo "--- SFGuardLocking.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardLocking.st

        echo ""

        echo "--- SFGuardLocking.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardLocking.st

        echo "\n###########################################\n"

        echo "--- SFGuardMonitoring.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardMonitoring.st

        echo ""

        echo "--- SFGuardMonitoring.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardMonitoring.st

        echo "\n###########################################\n"

        echo "--- SFModeSelector.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFModeSelector.st

        echo ""

        echo "--- SFModeSelector.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFModeSelector.st

        echo "\n###########################################\n"

        echo "--- SFMutingSeq.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFMutingSeq.st

        echo ""

        echo "--- SFMutingSeq.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFMutingSeq.st

        echo "\n###########################################\n"

        echo "--- SFOutControl.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFOutControl.st

        echo ""

        echo "--- SFOutControl.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFOutControl.st

        echo "\n###########################################\n"

        echo "--- SFSafelyLimitSpeed.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFSafelyLimitSpeed.st

        echo ""

        echo "--- SFSafelyLimitSpeed.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafelyLimitSpeed.st

        echo "\n###########################################\n"

        echo "--- SFSafeStop.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFSafeStop.st

        echo ""

        echo "--- SFSafeStop.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafeStop.st

        echo "\n###########################################\n"

        echo "--- SFSafetyRequest.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFSafetyRequest.st

        echo ""

        echo "--- SFSafetyRequest.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFSafetyRequest.st

        echo "\n###########################################\n"

        echo "--- SFTestableSafetySensor.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFTestableSafetySensor.st

        echo ""

        echo "--- SFTestableSafetySensor.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTestableSafetySensor.st

        echo "\n###########################################\n"

        echo "--- SFTwoHandControlTypeII.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeII.st

        echo ""

        echo "--- SFTwoHandControlTypeII.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeII.st

        echo "\n###########################################\n"

        echo "--- SFTwoHandControlTypeIII.st + Summarization + Concolic + No-Merge +  TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeIII.st

        echo ""

        echo "--- SFTwoHandControlTypeIII.st + Summarization + Concolic + Merge ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --cycle-bound ${CYCLE_BOUND} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeIII.st

        echo "\n###########################################\n"
    elif [[ "$1" == "2" ]]; then
        printf "# CSE + Summarization + Concolic w/o Merge (and TO)\n\n"

        echo "--- SFAntivalent.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFAntivalent.st

        echo "\n###########################################\n"

        echo "--- SFEDM.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFEDM.st

        echo "\n###########################################\n"

        echo "--- SFEmergencyStop.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFEmergencyStop.st

        echo "\n###########################################\n"

        echo "--- SFEnableSwitch.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFEnableSwitch.st

        echo "\n###########################################\n"

        echo "--- SFEquivalent.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFEquivalent.st

        echo "\n###########################################\n"

        echo "--- SFESPE.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFESPE.st


        echo "\n###########################################\n"

        echo "--- SFGuardLocking.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardLocking.st


        echo "\n###########################################\n"

        echo "--- SFGuardMonitoring.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFGuardMonitoring.st


        echo "\n###########################################\n"

        echo "--- SFModeSelector.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFModeSelector.st

        echo "\n###########################################\n"

        echo "--- SFMutingSeq.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFMutingSeq.st

        echo "\n###########################################\n"

        echo "--- SFOutControl.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFOutControl.st


        echo "\n###########################################\n"

        echo "--- SFSafelyLimitSpeed.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFSafelyLimitSpeed.st

        echo "\n###########################################\n"

        echo "--- SFSafeStop.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFSafeStop.st

        echo "\n###########################################\n"

        echo "--- SFSafetyRequest.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFSafetyRequest.st

        echo "\n###########################################\n"

        echo "--- SFTestableSafetySensor.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFTestableSafetySensor.st

        echo "\n###########################################\n"

        echo "--- SFTwoHandControlTypeII.st + Summarization + Concolic + No-Merge + TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeII.st

        echo "\n###########################################\n"

        echo "--- SFTwoHandControlTypeIII.st + Summarization + Concolic + No-Merge +  TO ---"
        ${EXECUTABLE_FOLDER}/ahorn --summarization --concolic --no-merge --cycle-bound ${CYCLE_BOUND} --time-out ${TIEMOUT} \
        --input-file ${BENCHMARK_FOLDER}/SFTwoHandControlTypeIII.st

        echo "\n###########################################\n"
    else
        printf "Missing argument: 0, 1, or 2.\n"
    fi
}

main "$@"



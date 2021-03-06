int currentCycle = 0;
int UNUSED = -999999999;

// Info about the registered command
int registeredExecutionCycle = -1;
int registeredCommandId = -1;
int registeredParamsCount = -1;
int registeredParamsArray = -1;

void printArray(int arr = -1) {
    if (arr == -1) {
        xsChatData("[]");
        return;
    }
    
    int size = xsArrayGetSize(arr);
    string result = "[";
    for (i = 0; < size) {
        result = result + xsArrayGetInt(arr, i);

        if (i < size - 1) {
            result = result + ", ";
        }
    }
    result = result + "]";
    xsChatData(result);
}

void sendResources(int wood = 0, int food = 0, int gold = 0, int stone = 0, int player = 0) {
    string msg = "Give ";
    if (player == UNUSED || player == -1) {
        msg = msg + "all players: ";
        
        // Apply to all players (except GAIA)
        player = -1;
    } else {
        msg = msg + "player " + player + ": ";
    }

    bool resourceSet = false;
    if (wood != UNUSED && wood != 0) {
        resourceSet = true;
        msg = msg + wood + " wood, ";
        xsEffectAmount(cModResource, cAttributeWood, cAttributeAdd, wood, player);
    }
    if (food != UNUSED && food != 0) {
        resourceSet = true;
        msg = msg + food + " food, ";
        xsEffectAmount(cModResource, cAttributeFood, cAttributeAdd, food, player);
    }
    if (gold != UNUSED && gold != 0) {
        resourceSet = true;
        msg = msg + gold + " gold, ";
        xsEffectAmount(cModResource, cAttributeGold, cAttributeAdd, gold, player);
    }
    if (stone != UNUSED && stone != 0) {
        resourceSet = true;
        msg = msg + stone + " stone, ";
        xsEffectAmount(cModResource, cAttributeStone, cAttributeAdd, stone, player);
    }
    if (resourceSet) {
        xsChatData(msg);
    }
}

int arg(int paramN = 0) {
    return (xsArrayGetInt(registeredParamsArray, paramN));
}

mutable void executeCommand(int commandId = -999999999) {
    xsChatData("Executing command on cycle: " + currentCycle);
    switch (commandId) {
        case 0: {
            // Params: None
            xsChatData("Hello World");
        }
        case 1: {
            // Params: 0: wood, 1: food, 2: gold, 3: stone, 4: player
            sendResources(arg(0), arg(1), arg(2), arg(3), arg(4));
        }
        default: {
            if (commandId == UNUSED) {
                xsChatData("Execute command called without commandId");
            } else {
                xsChatData("Unknown command [" + commandId + "] (" + arg(0) + ", " + arg(1) + ", " + arg(2) + ", " + arg(3) + ", " + arg(4) + ", " + arg(5) + ", " + arg(6) + ", " + arg(7) + ", " + arg(8) + ", " + arg(9) + ")");
            }
        }
    }
}

void emptyRegisteredParamsArray() {
    for (i = 0; < xsArrayGetSize(registeredParamsArray)) {
        xsArraySetInt(registeredParamsArray, i, UNUSED);
    }
}

// Run every 5 seconds to write current cycle to file
rule cycleUpdate
    active
    runImmediately
    minInterval 5
    maxInterval 5
{
    xsChatData("Cycle: " + currentCycle);
    xsEnableRule("writeCurrentCycleToFile");

    if (currentCycle == registeredExecutionCycle) {
        // executeCommandWrapper();
        executeCommand(registeredCommandId);
        xsEnableRule("readCommands");
    }

    currentCycle = currentCycle + 1;
}

// Run every second to read new commands
// File layout (all int32):
// 1:       Execution Cycle Number
// 2:       CommandId
// 3:       paramCount
// 4-13:    10 Parameters
rule readCommands
    active
    runImmediately
    minInterval 2
    maxInterval 2
{
    bool success = xsOpenFile("command");
    if (success == false) {
        xsCloseFile();
        return;
    }
    
    int executionCycle = xsReadInt();

    // If the registeredCycle (last executed one) is equal to the incoming one, 
    //      it means we're reading the old command, so ignore it.
    // If the cycle is different but the current cycle number has surpassed the incoming cycle, ignore it too.
    if (executionCycle == registeredExecutionCycle || currentCycle > executionCycle) {
        xsCloseFile();
        return;
    }

    registeredExecutionCycle = executionCycle;
    registeredCommandId = xsReadInt();
    registeredParamsCount = xsReadInt();
    emptyRegisteredParamsArray();

    xsChatData("Registered command. Cycle: " + executionCycle + ", id: " + registeredCommandId + ", pCount: " + registeredParamsCount);

    // Read params
    for(i = 0; < registeredParamsCount) {
        xsArraySetInt(registeredParamsArray, i, xsReadInt());
    }
    printArray(registeredParamsArray);
    xsDisableSelf();
    xsCloseFile();
}

rule writeCurrentCycleToFile
    active
    runImmediately
    highFrequency
{
    bool success = xsCreateFile(false);
    if (success) {
        xsWriteInt(currentCycle);
        xsCloseFile();
        xsDisableSelf();
    }
}

mutable void onStart() {
    // For users to overwrite if they want to execute something on main()
}

void main() {
    registeredParamsArray = xsArrayCreateInt(10, -1, "registeredParamsArray");

    onStart();
}

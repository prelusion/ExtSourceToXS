import {QueueHandler} from "@/classes/queue-handler";
import {SocketHandler} from "@/classes/socket-handler";
import {CommandEvent} from "@/interfaces/general";
import {ensure} from "@/util/general";

const {setInterval, clearInterval} = window;

export class GameHandler {
    private constructor() {
        /* Singleton */
    }

    private static _instance: GameHandler | null = null;

    private coreInterval = -1;
    private lastCommandCycle = -1;
    private _steamId = "";

    static get instance(): GameHandler {
        if (this._instance === null) {
            this._instance = new GameHandler();
        }
        return this._instance;
    }

    public async resetState(scenario: string): Promise<void> {
        await window.fs.deleteXsDataFiles(this.steamId, scenario);
        this.lastCommandCycle = -1;
        QueueHandler.instance.clear();
        this.stopCoreLoop();
    }

    public startCoreLoop(scenario: string) {
        this.coreInterval = setInterval(async () => {
            const cycle = await window.fs.readCycle(this.steamId, scenario);
            if (cycle !== undefined) {
                SocketHandler.instance.sendCycle(cycle);

                console.log("\n\n")
                console.log(`this.lastCommandCycle: ${this.lastCommandCycle}`);
                console.log(`cycle: ${cycle}`);
                console.log(`QueueHandler.isEmpty(): ${QueueHandler.instance.isEmpty()} (${QueueHandler.instance.length()})`);

                // If the last registered command execution cycle has passed and there are more commands
                // Send the next command to XS
                if (this.lastCommandCycle < cycle && !QueueHandler.instance.isEmpty()) {
                    const event: CommandEvent = ensure(QueueHandler.instance.dequeue());

                    console.log("Writing event: ")
                    console.log(event)

                    this.lastCommandCycle = event.executeCycleNumber;
                    await window.fs.writeEvent(this.steamId, scenario, event);
                    console.log(`writing finished...`);
                }
            }
        }, 1000);
    }

    public stopCoreLoop() {
        if (this.coreInterval !== null) {
            clearInterval(this.coreInterval);
        }
    }

    get steamId(): string {
        return this._steamId;
    }

    set steamId(value: string) {
        this._steamId = value;
    }
}
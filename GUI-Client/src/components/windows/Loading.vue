<template>
    <div id="loading" v-html="text"></div>
</template>

<script lang="ts">
import {GameHandler} from "@/classes/game-handler";
import {SocketHandler} from "@/classes/socket-handler";
import {io} from "socket.io-client";
import {defineComponent} from "vue";

const {setTimeout} = window;

export default defineComponent({
    name: "Loading",
    components: {},
    props: {},
    data() {
        return {
            timeout: -1,
            connectedToServer: false,
            retrievedSteamId: false,
            error: [] as Array<string>,
        };
    },
    mounted() {
        window.regedit.getSteamId().then(steamId => {
            GameHandler.instance.steamId = steamId;
            this.retrievedSteamId = true;
        });

        const socket = io("ws://localhost:80");
        socket.on("connect", () => {
            this.$store.state.connectionOk = true;
            SocketHandler.instance.socket = socket;

            if (SocketHandler.instance.room) {
                socket.emit('verifyRoomExists', SocketHandler.instance.room.id, (exists: boolean) => {
                    if (!exists) {
                        SocketHandler.instance.leaveRoom();

                        this.$store.commit("changeWindow", {
                            window: "Main",
                            data: {
                                'message': 'The server does not recognize the room anymore, please join or create a new one.'
                            }
                        });
                    }
                });
            }

            this.connectedToServer = true;
        });

        socket.on("disconnect", () => {
            this.$store.state.connectionOk = false;
        });
    },
    computed: {
        text() {
            let lines = [
                (!this.retrievedSteamId ? "Loading Steam ID..." : "Steam ID loaded successfully."),
                (!this.connectedToServer ? "Connecting to server..." : "Connected to server successfully."),
            ];

            if (this.error.length > 0)
                lines = lines.concat([""], this.error);

            return lines.join("<br>");
        },
    },
    methods: {
        checkIfLoadingComplete() {
            if (this.connectedToServer && this.retrievedSteamId) {
                setTimeout(() => this.$store.commit("changeWindow", "Main"), 200);
            }
        },
    },
    watch: {
        connectedToServer() {
            this.checkIfLoadingComplete();
        },
        retrievedSteamId() {
            this.checkIfLoadingComplete();
        },
    },
});

</script>

<style scoped lang="scss">
#loading {
    width: 100%;
    text-align: center;
}
</style>

<template>
    <div id="buttons">
        <button
            v-for="(config, index) in buttonConfig"
            v-bind:key="index"
            v-bind:disabled="config.disabled && config.disabled() || false"
            @click="clickedButton(index)"
        >
            {{ config.text }}
        </button>
    </div>
</template>

<script lang="ts">
import {defineComponent, PropType} from "vue";

export default defineComponent({
    name: "Buttons",
    components: {},
    props: {
        buttonConfig: {
            type: Array as PropType<Array<ButtonConfig>>,
            default: () => [],
            required: true,
        },
    },
    mounted() {
        // Runs
    },
    computed: {},
    methods: {
        async clickedButton(index: number) {
            const config = this.buttonConfig[index];
            if (config.callback) {
                await config.callback();
            }
            if (config.window) {
                this.$store.commit("changeWindow", config.window);
            }
        },
    },
    watch: {},
});

</script>

<style scoped lang="scss">
$padding: 20px - 10;

#buttons {
    position: absolute;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    width: 100%;
    bottom: 0;
    left: 0;
    padding: 0 $padding $padding $padding;

    button {
        width: 40%;
        padding: 10px;
        margin: 10px;
    }
}
</style>

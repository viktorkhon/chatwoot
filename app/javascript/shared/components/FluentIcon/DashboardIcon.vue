<script>
import BaseIcon from './Icon.vue';
// Import only the necessary icons dynamically
// The full import was causing the bundle size issue
const icons = {};

export default {
  name: 'FluentIcon',
  components: {
    BaseIcon,
  },
  props: {
    icon: {
      type: String,
      required: true,
    },
    size: {
      type: [String, Number],
      default: '20',
    },
    type: {
      type: String,
      default: 'outline',
    },
    viewBox: {
      type: String,
      default: '0 0 24 24',
    },
    iconLib: {
      type: String,
      default: 'fluent',
    },
  },
  data() {
    return { icons };
  },
  async created() {
    // Only import the dashboard-icons.json when the component is actually used
    if (Object.keys(this.icons).length === 0) {
      const iconsModule = await import('./dashboard-icons.json');
      Object.assign(this.icons, iconsModule.default);
    }
  },
};
</script>

<template>
  <BaseIcon
    :size="size"
    :icon="icon"
    :type="type"
    :icons="icons"
    :view-box="viewBox"
    :icon-lib="iconLib"
  />
</template>

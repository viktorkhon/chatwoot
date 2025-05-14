<script>
import BaseIcon from './Icon.vue';
import essentialIcons from './essential-icons.json';

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
    return { 
      icons: essentialIcons,
      fullIconsLoaded: false
    };
  },
  computed: {
    iconKey() {
      return `${this.icon}-${this.type}`;
    },
    isIconInEssential() {
      return !!this.icons[this.iconKey];
    }
  },
  methods: {
    loadFullIcons() {
      if (this.fullIconsLoaded) return Promise.resolve();
      
      return import('./dashboard-icons.json').then(module => {
        this.icons = { ...this.icons, ...module.default };
        this.fullIconsLoaded = true;
      });
    }
  },
  mounted() {
    // If the icon is not in the essential set, load the full set
    if (!this.isIconInEssential) {
      this.loadFullIcons();
    } else {
      // Preload the full icon set after the page has loaded
      window.addEventListener('load', () => {
        // Wait a bit to ensure the main page components are loaded first
        setTimeout(() => {
          this.loadFullIcons();
        }, 2000);
      });
    }
  }
};
</script>

<template>
  <BaseIcon
    v-if="isIconInEssential || fullIconsLoaded"
    :size="size"
    :icon="icon"
    :type="type"
    :icons="icons"
    :view-box="viewBox"
    :icon-lib="iconLib"
  />
  <span v-else style="width: 20px; height: 20px; display: inline-block;"></span>
</template>

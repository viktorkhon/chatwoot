<script>
import BaseIcon from './Icon.vue';
// Define a global icons cache to prevent multiple loads
const iconsCache = {
  data: null,
  loading: false,
  error: null,
  callbacks: []
};

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
      icons: {},
      loading: false,
      error: null,
    };
  },
  created() {
    this.loadIcons();
  },
  methods: {
    async loadIcons() {
      // If we already have icons loaded in this component instance, don't reload
      if (Object.keys(this.icons).length > 0) return;
      
      // If the global cache already has data, use it immediately
      if (iconsCache.data) {
        this.icons = iconsCache.data;
        return;
      }

      // If there's an error in the global cache, propagate it
      if (iconsCache.error) {
        this.error = iconsCache.error;
        return;
      }

      // Set local loading state
      this.loading = true;

      // If already loading globally, wait for that to complete
      if (iconsCache.loading) {
        iconsCache.callbacks.push((data, error) => {
          this.icons = data || {};
          this.error = error;
          this.loading = false;
        });
        return;
      }

      // Start global loading
      iconsCache.loading = true;
      
      try {
        // Use a fetch with a timeout instead of import for better error handling
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
        
        const response = await fetch('./dashboard-icons.json', { 
          signal: controller.signal 
        });
        
        clearTimeout(timeoutId);
        
        if (!response.ok) {
          throw new Error(`Failed to load icons: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        
        // Update global cache
        iconsCache.data = data;
        this.icons = data;
        
        // Notify all waiting components
        iconsCache.callbacks.forEach(callback => callback(data, null));
      } catch (error) {
        console.error('Failed to load dashboard icons:', error);
        
        // Update global cache with error
        iconsCache.error = error;
        this.error = error;
        
        // Notify all waiting components about the error
        iconsCache.callbacks.forEach(callback => callback(null, error));
      } finally {
        // Reset global loading state
        iconsCache.loading = false;
        iconsCache.callbacks = [];
        this.loading = false;
      }
    }
  },
};
</script>

<template>
  <div v-if="error" class="icon-error" title="Icon failed to load">
    <!-- Fallback for when icons fail to load -->
    <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="24" height="24" fill="currentColor" fill-opacity="0.2"/>
      <path d="M12 6V12L16 16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
    </svg>
  </div>
  <div v-else-if="loading" class="icon-loading">
    <!-- Loading indicator -->
    <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-opacity="0.3" stroke-width="2"/>
    </svg>
  </div>
  <BaseIcon
    v-else
    :size="size"
    :icon="icon"
    :type="type"
    :icons="icons"
    :view-box="viewBox"
    :icon-lib="iconLib"
  />
</template>

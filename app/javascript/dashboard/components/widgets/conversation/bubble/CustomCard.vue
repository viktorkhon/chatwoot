<template>
  <div class="card-container">
    <div v-if="!hasValidItems" class="empty-state">
      <p>No items to display</p>
    </div>
    
    <div v-for="(item, index) in safeItems" :key="index" class="card">
      <div v-if="item.image_url" class="card-media">
        <img :src="item.image_url" :alt="item.title" class="card-image" @error="handleImageError($event, index)" />
      </div>
      <div class="card-content">
        <h3 v-if="item.title" class="card-title" v-html="renderMarkdown(item.title, item.supports_markdown)"></h3>
        <div v-if="item.description" class="card-description" v-html="renderMarkdown(item.description, item.supports_markdown)"></div>
        <div v-if="item.reason" class="card-reason">
          <h4 class="card-reason-title">Reason for Suggestion</h4>
          <div class="card-reason-content" v-html="renderMarkdown(item.reason, item.supports_markdown)"></div>
        </div>
        <div v-if="item.price" class="card-price" v-html="renderMarkdown(item.price, item.supports_markdown)"></div>
        <div v-if="item.actions && item.actions.length" class="card-actions">
          <button
            v-for="(action, actionIndex) in item.actions"
            :key="actionIndex"
            class="card-action-button"
            :class="{ 'is-link': action.type === 'link', 'is-postback': action.type === 'postback' }"
            @click="handleAction(action, item)"
          >
            {{ action.text }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { renderMarkdown } from 'dashboard/helper/customCardHelper';

export default {
  name: 'CustomCard',
  props: {
    items: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
  data() {
    console.log('[CustomCard] Initializing data()');
    return {
      imageErrors: {},
      initTime: new Date().toISOString(),
    };
  },
  computed: {
    hasValidItems() {
      const result = this.items && Array.isArray(this.items) && this.items.length > 0;
      console.log(`[CustomCard] hasValidItems = ${result}, items length: ${this.items?.length || 0}`);
      return result;
    },
    safeItems() {
      if (!this.hasValidItems) {
        console.log('[CustomCard] No valid items, returning empty array');
        return [];
      }
      
      console.log('[CustomCard] Processing items:', JSON.stringify(this.items.slice(0, 1)));
      
      // Map items to ensure all expected properties exist
      return this.items.map((item, index) => {
        const safeItem = {
          title: item.title || 'No Title',
          description: item.description || '',
          image_url: item.image_url || '',
          reason: item.reason || '',
          price: item.price || '',
          actions: Array.isArray(item.actions) ? item.actions : [],
          supports_markdown: !!item.supports_markdown,
          custom_fields: item.custom_fields || {},
        };
        
        console.log(`[CustomCard] Processed item ${index}:`, safeItem.title);
        return safeItem;
      });
    },
  },
  beforeCreate() {
    console.log('[CustomCard] BEFORE_CREATE hook called');
  },
  created() {
    console.log('[CustomCard] CREATED hook called with', {
      itemsLength: this.items?.length || 0,
      hasValidItems: this.items && Array.isArray(this.items) && this.items.length > 0,
      firstItem: this.items?.[0],
      initTime: this.initTime,
    });
    
    // Do a direct console.log of the first item structure
    if (this.items?.[0]) {
      console.log('[CustomCard] First item structure:', JSON.stringify(this.items[0]));
    } else {
      console.warn('[CustomCard] No items available in created hook');
    }
  },
  mounted() {
    console.log('[CustomCard] MOUNTED hook called with', {
      itemsLength: this.items?.length || 0,
      hasValidItems: this.hasValidItems,
      elementInDOM: !!this.$el && document.body.contains(this.$el),
      initTime: this.initTime,
    });
    
    // Check if the component is actually in the DOM
    if (!this.$el || !document.body.contains(this.$el)) {
      console.warn('[CustomCard] Component mounted but not in DOM!');
      // Try to add to DOM as an emergency fallback
      const emergencyContainer = document.createElement('div');
      emergencyContainer.style.cssText = 'position: fixed; bottom: 20px; right: 20px; background: white; padding: 10px; border: 2px solid red; z-index: 9999;';
      emergencyContainer.innerHTML = `<h3>Emergency CustomCard</h3><p>Items: ${this.items?.length || 0}</p>`;
      document.body.appendChild(emergencyContainer);
    } else {
      console.log('[CustomCard] Confirmed component is in DOM');
      // Highlight the element in the DOM
      this.$el.style.outline = '3px dashed #E91E63';
      setTimeout(() => {
        this.$el.style.outline = '';
      }, 3000);
    }
  },
  updated() {
    console.log('[CustomCard] UPDATED hook called with', {
      itemsLength: this.items?.length || 0,
      hasValidItems: this.hasValidItems,
      initTime: this.initTime,
      timeNow: new Date().toISOString(),
    });
  },
  beforeUnmount() {
    console.log('[CustomCard] About to UNMOUNT, existed for', new Date() - new Date(this.initTime), 'ms');
  },
  methods: {
    handleAction(action, item) {
      console.log('[CustomCard] Action clicked:', action.text);
      
      if (action.type === 'link') {
        window.open(action.uri, '_blank', 'noopener,noreferrer');
      } else if (action.type === 'postback') {
        emitter.emit(BUS_EVENTS.CARD_ACTION, action.payload);
      }
    },
    renderMarkdown,
    handleImageError(event, index) {
      console.warn(`[CustomCard] Image failed to load for item ${index}`);
      this.imageErrors[index] = true;
      event.target.style.display = 'none';
    },
  },
};
</script>

<style lang="scss" scoped>
.card-container {
  display: flex;
  flex-direction: column;
  width: 100%;
}

.card {
  background-color: white;
  border-radius: 0.5rem;
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  max-width: 20rem;
  margin-bottom: 1rem;
  border: 1px solid #e5e7eb;
}

.empty-state {
  background-color: #f9fafb;
  border-radius: 0.5rem;
  padding: 1rem;
  text-align: center;
  margin-bottom: 1rem;
  border: 1px solid #e5e7eb;
  color: #4b5563;
}

.card-media {
  position: relative;
}

.card-image {
  width: 100%;
  height: 12rem;
  object-fit: cover;
}

.card-content {
  padding: 1rem;
}

.card-title {
  font-size: 1rem;
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 0.5rem;
}

.card-reason {
  background-color: #f9fafb;
  padding: 0.75rem;
  border-radius: 0.375rem;
  margin-bottom: 0.75rem;
}

.card-reason-title {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.25rem;
}

.card-reason-content {
  font-size: 0.875rem;
  color: #4b5563;
}

.card-description {
  font-size: 0.875rem;
  color: #4b5563;
  margin-bottom: 1rem;
}

.card-price {
  font-size: 1rem;
  font-weight: 600;
  color: #1f2937;
  text-align: center;
  margin-bottom: 0.75rem;
}

.card-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.card-action-button {
  padding: 0.375rem 0.75rem;
  font-size: 0.875rem;
  border-radius: 0.375rem;
  transition-property: background-color;
  transition-duration: 200ms;
  background-color: #f3f4f6;
  color: #374151;
}

.card-action-button:hover {
  background-color: #e5e7eb;
}

.card-action-button.is-link {
  background-color: #e0f2fe;
  color: #0369a1;
}

.card-action-button.is-link:hover {
  background-color: #bae6fd;
}

.card-action-button.is-postback {
  background-color: #dcfce7;
  color: #15803d;
}

.card-action-button.is-postback:hover {
  background-color: #bbf7d0;
}
</style> 
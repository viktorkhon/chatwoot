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
    return {
      imageErrors: {},
    };
  },
  computed: {
    hasValidItems() {
      return this.items && Array.isArray(this.items) && this.items.length > 0;
    },
    safeItems() {
      if (!this.hasValidItems) return [];
      
      // Map items to ensure all expected properties exist
      return this.items.map(item => ({
        title: item.title || 'No Title',
        description: item.description || '',
        image_url: item.image_url || '',
        reason: item.reason || '',
        price: item.price || '',
        actions: Array.isArray(item.actions) ? item.actions : [],
        supports_markdown: !!item.supports_markdown,
        custom_fields: item.custom_fields || {},
      }));
    },
  },
  created() {
    console.log('[CustomCard] Component CREATED with', {
      itemsLength: this.items?.length || 0,
      hasValidItems: this.hasValidItems,
      firstItem: this.items?.[0]
    });
  },
  mounted() {
    console.log('[CustomCard] Component MOUNTED with', {
      itemsLength: this.items?.length || 0,
      hasValidItems: this.hasValidItems
    });
    
    // Check if the component is actually in the DOM
    if (!this.$el || !document.body.contains(this.$el)) {
      console.warn('[CustomCard] Component mounted but not in DOM!');
    } else {
      console.log('[CustomCard] Confirmed component is in DOM');
    }
  },
  updated() {
    console.log('[CustomCard] Component UPDATED with', {
      itemsLength: this.items?.length || 0,
      hasValidItems: this.hasValidItems
    });
  },
  beforeUnmount() {
    console.log('[CustomCard] Component about to UNMOUNT');
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
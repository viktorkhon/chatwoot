<template>
  <div class="card-container custom-card-debug">
    <div class="debug-info p-2 mb-2 bg-yellow-100 border border-yellow-400 text-yellow-800 hidden" style="display: block !important;">
      Debug: Custom Card component with {{items.length}} items
    </div>
    
    <!-- Basic hardcoded version for testing -->
    <div style="border: 4px dashed green; padding: 16px; background: white; margin: 8px 0;">
      <h2 style="color: black; font-size: 18px; font-weight: bold;">THIS IS A HARDCODED TEST CARD</h2>
      <p style="color: black;">If you can see this, the CustomCard component is being rendered.</p>
    </div>
    
    <!-- Dynamic version -->
    <div v-for="(item, index) in items" :key="index" class="card custom-card-item-debug">
      <div v-if="item.image_url" class="card-media">
        <img :src="item.image_url" :alt="item.title" class="card-image" />
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
            @click="handleAction(action)"
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
    },
  },
  mounted() {
    console.log(`[CustomCard] Dashboard component mounted with ${this.items.length} items`);
    console.log(`[CustomCard] Items:`, this.items);
  },
  methods: {
    handleAction(action) {
      if (action.type === 'link') {
        window.open(action.uri, '_blank', 'noopener,noreferrer');
      } else if (action.type === 'postback') {
        emitter.emit(BUS_EVENTS.CARD_ACTION, action.payload);
      }
    },
    renderMarkdown,
  },
};
</script>

<style lang="scss" scoped>
.card-container {
  display: flex;
  flex-direction: column;
}

.card {
  background-color: white;
  border-radius: 0.5rem;
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  max-width: 20rem;
  margin-bottom: 1rem;
}

.separator {
  border-top: 1px solid #e5e7eb;
  margin: 0.75rem 0;
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

/* Dark mode could be added with media queries or class-based toggles */

.custom-card-debug {
  border: 2px solid red !important;
  padding: 4px !important;
  margin: 8px 0 !important;
}

.custom-card-item-debug {
  border: 2px solid blue !important;
}
</style> 
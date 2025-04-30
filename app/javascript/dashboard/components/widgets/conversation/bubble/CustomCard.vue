<template>
  <div class="card-container">
    <!-- Empty state handling for when no items are provided -->
    <div v-if="!items || items.length === 0" class="empty-state">
      <p>No card items to display</p>
    </div>
    
    <!-- Iterate through each card item in the items array -->
    <div v-for="(item, index) in items" :key="index" class="card">
      <!-- Display card image if available -->
      <div v-if="item.image_url" class="card-media">
        <!-- Use onError handler to display fallback if image fails to load -->
        <img 
          :src="item.image_url" 
          :alt="item.title" 
          class="card-image" 
          @error="handleImageError" 
        />
      </div>
      <div class="card-content">
        <!-- Card title with optional markdown support -->
        <h3 v-if="item.title" class="card-title" v-html="renderMarkdown(item.title, item.supports_markdown)"></h3>
        
        <!-- Description section with optional markdown support -->
        <div v-if="item.description" class="card-description">
          <h4 class="card-section-title">Product Description</h4>
          <div v-html="renderMarkdown(item.description, item.supports_markdown)"></div>
        </div>
        
        <!-- Reason section with optional markdown support -->
        <div v-if="item.reason" class="card-reason">
          <h4 class="card-section-title">Reason for Suggestion</h4>
          <div v-html="renderMarkdown(item.reason, item.supports_markdown)"></div>
        </div>
        
        <!-- Price display with optional markdown support -->
        <div v-if="item.price" class="card-price" v-html="renderMarkdown(item.price, item.supports_markdown)"></div>
        
        <!-- Card action buttons -->
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

/**
 * CustomCard component
 * 
 * This component displays cards with various information fields including
 * title, description, reason, price, and action buttons. It's designed to work
 * specifically with the 'custom_cards' content type in messages.
 */
export default {
  name: 'CustomCard',
  props: {
    // Array of card items to display
    items: {
      type: Array,
      required: true,
      // Default to empty array to avoid issues if null is passed
      default: () => [],
    },
  },
  methods: {
    /**
     * Handle image loading errors by setting a CSS class
     * This allows for styling failed images differently
     */
    handleImageError(e) {
      e.target.classList.add('image-error');
      // Log a useful error message for debugging
      console.error(`Failed to load image: ${e.target.src}`);
    },
    
    /**
     * Handle actions when a card button is clicked
     * - For 'link' type: Open URL in new tab
     * - For 'postback' type: Emit event to be handled elsewhere
     */
    handleAction(action) {
      if (!action || !action.type) return;
      
      if (action.type === 'link') {
        // Open external links in new tab with security attributes
        window.open(action.uri, '_blank', 'noopener,noreferrer');
      } else if (action.type === 'postback') {
        // Emit event for postback actions to be handled by parent components
        emitter.emit(BUS_EVENTS.CARD_ACTION, action.payload);
      }
    },
    
    /**
     * Render markdown content from plain text
     * Imported from shared helper function
     */
    renderMarkdown,
  },
};
</script>

<style lang="scss" scoped>
// Card container styles
.card-container {
  @apply flex flex-col gap-4;
}

// Empty state styles
.empty-state {
  @apply p-4 text-center text-slate-500 bg-slate-50 rounded-lg border border-slate-200;
}

// Individual card styles
.card {
  @apply bg-white dark:bg-slate-800 rounded-lg overflow-hidden shadow-sm max-w-[24rem];
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  
  &:hover {
    @apply shadow-md;
    transform: translateY(-2px);
  }
}

// Image container styles
.card-media {
  @apply relative;
  height: 180px;
  background-color: #f8fafc;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

// Image styles with error handling
.card-image {
  @apply w-full h-full object-contain;
  max-height: 180px;
  
  &.image-error {
    @apply opacity-50;
    max-width: 50%; // Smaller size for error state
  }
}

// Content container styles
.card-content {
  @apply p-4;
}

// Title styles
.card-title {
  @apply text-lg font-semibold text-slate-900 dark:text-slate-100 mb-3 text-center;
}

// Section title styles
.card-section-title {
  @apply text-sm font-medium text-slate-700 dark:text-slate-300 mb-2 pb-1 border-b border-slate-200 dark:border-slate-700;
}

// Description and reason styles
.card-description, .card-reason {
  @apply text-sm text-slate-600 dark:text-slate-300 mb-4 p-3 bg-slate-50 dark:bg-slate-900 rounded-md;
}

// Price styles
.card-price {
  @apply text-base font-semibold text-slate-900 dark:text-slate-100 text-center mb-3 p-2 bg-green-50 dark:bg-green-900/20 rounded-md;
}

// Action button container
.card-actions {
  @apply flex flex-wrap gap-2 justify-center mt-4;
}

// Action button styles
.card-action-button {
  @apply px-3 py-1.5 text-sm rounded-md transition-colors duration-200;
  @apply bg-slate-100 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600;
  @apply text-slate-700 dark:text-slate-200;

  // Link button styles
  &.is-link {
    @apply bg-woot-100 hover:bg-woot-200 dark:bg-woot-900 dark:hover:bg-woot-800;
    @apply text-woot-700 dark:text-woot-200;
  }

  // Postback button styles
  &.is-postback {
    @apply bg-green-100 hover:bg-green-200 dark:bg-green-900 dark:hover:bg-green-800;
    @apply text-green-700 dark:text-green-200;
  }
}
</style> 
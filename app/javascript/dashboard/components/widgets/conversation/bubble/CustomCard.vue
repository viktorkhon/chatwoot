<template>
  <div class="card-container">
    <!-- Empty state handling for when no items are provided -->
    <div v-if="!items || items.length === 0" class="empty-state">
      <p>No card items to display</p>
    </div>
    
    <!-- Debug info (will be removed in production) -->
    <div v-if="isDebugMode" class="debug-info">
      <p>Card Items: {{ items.length }}</p>
      <p v-if="items.length > 0">First item has image_url: {{ items[0].image_url ? 'Yes' : 'No' }}</p>
    </div>
    
    <!-- Iterate through each card item in the items array -->
    <div v-for="(item, index) in items" :key="index" class="card">
      <!-- Display card image if available - with direct src binding -->
      <div v-if="getImageUrl(item)" class="card-media">
        <img 
          :src="getImageUrl(item)" 
          :alt="item.title || 'Product image'" 
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
  data() {
    return {
      // Enable debug mode for troubleshooting - set to false for production
      isDebugMode: process.env.NODE_ENV !== 'production',
      loadedImages: 0,
      errorImages: 0,
    };
  },
  mounted() {
    // Log items when component mounts for debugging
    this.logItemsInfo();
  },
  methods: {
    /**
     * Log information about the items for debugging
     */
    logItemsInfo() {
      console.log('[CustomCard] Component mounted with', this.items.length, 'items');
      
      // Log first item details if available
      if (this.items.length > 0) {
        const item = this.items[0];
        console.log('[CustomCard] First item details:');
        console.log('- Title:', item.title);
        console.log('- Has description:', !!item.description);
        console.log('- Has reason:', !!item.reason);
        console.log('- Has price:', !!item.price);
        console.log('- Image URL:', item.image_url);
        console.log('- Actions:', item.actions ? item.actions.length : 0);
      }
    },
    
    /**
     * Safely extract image URL from item, handling different property names
     * This ensures compatibility with different data formats and sources.
     */
    getImageUrl(item) {
      // Check for direct image_url property first
      if (item.image_url) {
        return item.image_url;
      }
      
      // Check for alternative property names
      if (item.imageUrl) {
        return item.imageUrl;
      }
      
      // Check for media_url as fallback (used in some card formats)
      if (item.media_url) {
        return item.media_url;
      }
      
      // Check camelCase version
      if (item.mediaUrl) {
        return item.mediaUrl;
      }
      
      // No image URL found
      return null;
    },
    
    /**
     * Handle image loading errors by setting a CSS class
     * This allows for styling failed images differently
     */
    handleImageError(e) {
      e.target.classList.add('image-error');
      this.errorImages++;
      // Log a useful error message for debugging
      console.error(`Failed to load image: ${e.target.src}`);
      
      // Set a default placeholder image
      e.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjIwMCIgaGVpZ2h0PSIyMDAiIGZpbGw9IiNFNUU3RUIiLz48cGF0aCBkPSJNMTAwIDcwQzEwMCA3OC4yODQzIDkzLjI4NDMgODUgODUgODVDNzYuNzE1NyA4NSA3MCA3OC4yODQzIDcwIDcwQzcwIDYxLjcxNTcgNzYuNzE1NyA1NSA4NSA1NUM5My4yODQzIDU1IDEwMCA2MS43MTU3IDEwMCA3MFoiIGZpbGw9IiM5NEE2QjYiLz48cGF0aCBkPSJNMTQwIDE1MkgxMzAuMzc3TDEyMCAxMjBMOTAgMTYwTDYwIDEyMEwzMCAxNjBIMzBWMTY1SDE3MFYxNTJIMTQwWiIgZmlsbD0iIzk0QTZCNiIvPjwvc3ZnPg==';
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
  border-bottom: 1px solid #e2e8f0;
}

// Image styles with error handling
.card-image {
  max-height: 180px;
  max-width: 100%;
  display: block;
  margin: 0 auto;
  object-fit: contain;
  
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
  @apply text-sm font-medium text-slate-700 dark:text-slate-300 mb-1;
}

// Description styles
.card-description {
  @apply mb-3;
}

// Reason styles
.card-reason {
  @apply mb-3 text-sm text-slate-600 dark:text-slate-400;
}

// Price styles
.card-price {
  @apply mb-3 font-semibold text-teal-600 dark:text-teal-400;
}

// Action container styles
.card-actions {
  @apply flex flex-wrap gap-2 mt-4;
}

// Action button styles
.card-action-button {
  @apply px-4 py-2 rounded-md text-sm font-medium;
  
  &.is-link {
    @apply bg-slate-100 text-slate-800 hover:bg-slate-200;
  }
  
  &.is-postback {
    @apply bg-slate-800 text-white hover:bg-slate-700;
  }
}
</style> 
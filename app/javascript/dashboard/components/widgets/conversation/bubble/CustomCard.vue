<template>
  <div class="card-container">

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
        // Attempt to get the global N8N URL (assuming it's set on the window object by Rails)
        const n8nProductInfoUrl = window.N8N_RETRIEVE_PRODUCT_URL;

        if (n8nProductInfoUrl && action.payload && action.payload.product_data) {
          // This is our specific postback for product details to n8n
          fetch(n8nProductInfoUrl, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(action.payload.product_data),
          })
            .then(response => {
              if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
              }
              // Assuming n8n responds with JSON. Adjust if it's text or other content type.
              return response.json(); 
            })
            .then(data => {
              // You might want to do something with the n8n response here
              // For example, log it, or emit another event if Chatwoot needs to react to the response
              if (this.isDebugMode) {
                console.log('N8N webhook response:', data);
              }
              // Optionally, you could emit an event to notify other parts of the app
              // emitter.emit(BUS_EVENTS.N8N_RESPONSE_RECEIVED, data);
            })
            .catch(error => {
              console.error('Error calling N8N webhook for product details:', error);
              // Optionally, provide user feedback about the error
            });
        } else {
          // Fallback for other types of postback actions
          emitter.emit(BUS_EVENTS.CARD_ACTION, action.payload);
        }
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
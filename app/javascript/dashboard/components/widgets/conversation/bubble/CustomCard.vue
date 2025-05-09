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
          <template v-for="(action, actionIndex) in item.actions" :key="actionIndex">
            <a
              v-if="action.type === 'link'"
              :href="action.uri"
              target="_blank"
              rel="noopener noreferrer"
              class="card-action-button"
              :class="{ 'is-link': true }" 
            >
              {{ action.text }}
            </a>
            <button
              v-else
              type="button" 
              class="card-action-button"
              :class="{ 'is-postback': action.type === 'postback' }"
              @click="handleAction(action)"
            >
              {{ action.text }}
            </button>
          </template>
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
    // this.logItemsInfo(); // Commented out: this method is not defined
    if (this.isDebugMode) {
      console.log('CustomCard mounted. Items received:', JSON.parse(JSON.stringify(this.items)));
    }
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
      console.log('--- CustomCard.vue (widgets/conversation/bubble) handleAction CALLED --- Action object:', JSON.parse(JSON.stringify(action)));

      if (!action || !action.type) {
        console.error('CustomCard: Invalid action or missing action type', action);
        return;
      }

      // Note: Text change from 'Select' to 'More Details' should ideally happen at data source.
      if (action.text === 'Select') {
        console.warn("CustomCard: Action text 'Select' found. Source data should provide 'More Details'.");
      }

      // This method now only handles postback, as links are rendered as <a> tags.
      if (action.type === 'postback') {
        console.log('CustomCard: Handling postback action. Payload:', JSON.parse(JSON.stringify(action.payload)));
        const n8nProductInfoUrl = window.chatwootConfig?.n8nRetrieveProductUrl;
        console.log('CustomCard: N8N URL from window.chatwootConfig:', n8nProductInfoUrl);

        if (n8nProductInfoUrl && action.payload) {
          const productData = action.payload.product_data || 
            (action.payload.product_id ? {
              product_id: action.payload.product_id,
              product_name: action.payload.product_name || 'Unknown Product'
            } : null);

          if (!productData) {
            console.error('CustomCard: No product data in payload for N8N call. Payload:', JSON.parse(JSON.stringify(action.payload)));
            console.log('CustomCard: Emitting BUS_EVENTS.CARD_ACTION as fallback.');
            emitter.emit(BUS_EVENTS.CARD_ACTION, action.payload);
            return;
          }

          console.log('CustomCard: Sending data to N8N webhook. URL:', n8nProductInfoUrl, 'Data:', JSON.parse(JSON.stringify(productData)));
          fetch(n8nProductInfoUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(productData),
          })
            .then(response => {
              console.log('CustomCard: N8N fetch response. Status:', response.status);
              if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
              return response.json();
            })
            .then(data => {
              console.log('CustomCard: N8N response data:', data);
              emitter.emit(BUS_EVENTS.N8N_RESPONSE_RECEIVED, data);
            })
            .catch(error => {
              console.error('CustomCard: Error calling N8N webhook:', error);
            });
        } else {
          if (!n8nProductInfoUrl) console.warn('CustomCard: N8N URL not configured.');
          if (!action.payload) console.warn('CustomCard: Postback action payload is missing.');
          console.log('CustomCard: N8N conditions not met. Emitting BUS_EVENTS.CARD_ACTION.');
          emitter.emit(BUS_EVENTS.CARD_ACTION, action.payload);
        }
      } else {
        // This case should ideally not be reached if links are <a> tags
        console.warn('CustomCard: handleAction called for non-postback action type:', action.type, 'This might be unexpected.');
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
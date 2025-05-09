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
      console.log('--- CustomCard handleAction CALLED --- Action object:', JSON.parse(JSON.stringify(action))); // Ensure this is the VERY FIRST line
      
      if (!action || !action.type) {
        console.error('CustomCard: Invalid action or missing action type', action);
        return;
      }
      
      // Replace "Select" button text with "More Details" if present
      // This is a visual change only if the source data still contains 'Select'
      // Best practice is to change 'Select' to 'More Details' in the source data itself.
      if (action.text === 'Select') {
        console.warn("CustomCard: Action text 'Select' found. Consider changing this in the source data to 'More Details'.");
        // action.text = 'More Details'; // Temporarily disabled to prefer source data change
      }
      
      if (action.type === 'link') {
        console.log('CustomCard: Handling link action. Opening URI:', action.uri);
        // Open external links in new tab with security attributes
        window.open(action.uri, '_blank', 'noopener,noreferrer');
      } else if (action.type === 'postback') {
        console.log('CustomCard: Handling postback action. Payload:', JSON.parse(JSON.stringify(action.payload)));
        // Attempt to get the global N8N URL (assuming it's set on the window object by Rails)
        const n8nProductInfoUrl = window.chatwootConfig?.n8nRetrieveProductUrl;
        console.log('CustomCard: N8N URL from window.chatwootConfig:', n8nProductInfoUrl);
        
        // If we have product data in the payload, send it to n8n webhook
        if (n8nProductInfoUrl && action.payload) {
          // If product_data doesn't exist but we have product information directly in payload
          const productData = action.payload.product_data || 
            (action.payload.product_id ? {
              product_id: action.payload.product_id,
              product_name: action.payload.product_name || 'Unknown Product'
            } : null);
          
          if (!productData) {
            console.error('CustomCard: No product data found in payload for N8N call. Payload was:', JSON.parse(JSON.stringify(action.payload)));
            // Still emit the event as fallback for other postback types
            console.log('CustomCard: Falling back to default postback event emission (BUS_EVENTS.CARD_ACTION).');
            emitter.emit(BUS_EVENTS.CARD_ACTION, action.payload);
            return;
          }
          
          console.log('CustomCard: Sending data to N8N webhook. URL:', n8nProductInfoUrl, 'Data:', JSON.parse(JSON.stringify(productData)));
          
          fetch(n8nProductInfoUrl, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(productData),
          })
            .then(response => {
              console.log('CustomCard: N8N webhook fetch response received. Status:', response.status);
              if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
              }
              // Assuming n8n responds with JSON. Adjust if it's text or other content type.
              return response.json(); 
            })
            .then(data => {
              console.log('CustomCard: N8N webhook response data:', data);
              // Optionally, you could emit an event to notify other parts of the app
              emitter.emit(BUS_EVENTS.N8N_RESPONSE_RECEIVED, data);
            })
            .catch(error => {
              console.error('CustomCard: Error calling N8N webhook for product details:', error);
              // Optionally, provide user feedback about the error
            });
        } else {
          if (!n8nProductInfoUrl) {
            console.warn('CustomCard: N8N Product Info URL (window.chatwootConfig.n8nRetrieveProductUrl) is not configured.');
          }
          if (!action.payload) {
            console.warn('CustomCard: Action payload is missing for postback.');
          }
          console.log('CustomCard: Conditions for N8N call not met. Falling back to default postback event emission (BUS_EVENTS.CARD_ACTION).');
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
<template>
  <div class="custom-chat-card chat-bubble agent bg-white dark:bg-slate-800 max-w-56 rounded-lg overflow-hidden custom-chat-card-debug" style="display: block !important; visibility: visible !important; opacity: 1 !important; z-index: 9999 !important;">
    <div class="debug-info p-2 mb-2 bg-green-100 border border-green-400 text-green-800" style="display: block !important;">
      Debug: CustomChatCard for "{{title}}"
    </div>
    <div class="debug-info p-2 mb-2 bg-blue-100 border border-blue-400 text-blue-800" style="display: block !important;">
      Media URL: {{mediaUrl || imageUrl}}
    </div>
    <img v-if="mediaUrl || imageUrl" class="w-full object-contain max-h-[150px] rounded-[5px]" :src="mediaUrl || imageUrl" style="max-width: 100% !important;" />
    <div class="custom-chat-card-body" style="padding: 10px !important;">
      <h4 class="custom-chat-card-title" v-html="renderMarkdown(title, supportsMarkdown)" style="color: black !important; font-weight: bold !important;"></h4>
      
      <div v-if="description" class="custom-chat-card-section" style="background-color: #f8f9fa !important; margin: 8px 0 !important; padding: 8px !important;">
        <h5 class="custom-chat-card-section-title" style="color: #333 !important;">Product Description</h5>
        <p class="custom-chat-card-description" v-html="renderMarkdown(description, supportsMarkdown)" style="color: #333 !important;"></p>
      </div>
      
      <div v-if="reason" class="custom-chat-card-section" style="background-color: #f8f9fa !important; margin: 8px 0 !important; padding: 8px !important;">
        <h5 class="custom-chat-card-section-title" style="color: #333 !important;">Reason for Suggestion</h5>
        <p class="custom-chat-card-reason" v-html="renderMarkdown(reason, supportsMarkdown)" style="color: #333 !important;"></p>
      </div>
      
      <p v-if="price" class="custom-chat-card-price" v-html="renderMarkdown(price, supportsMarkdown)" style="color: #333 !important; font-weight: bold !important;"></p>
      
      <div v-if="customFields" class="custom-chat-card-fields">
        <div v-for="(field, index) in customFields" :key="index" class="custom-chat-card-field">
          <span class="custom-chat-card-field-label">{{ field.label }}:</span>
          <span class="custom-chat-card-field-value">{{ field.value }}</span>
        </div>
      </div>
      <CustomCardButton v-for="action in actions" :key="action.id" :action="action" />
    </div>
  </div>
</template>

<script>
import CustomCardButton from './CustomCardButton.vue';
import { renderMarkdown } from 'dashboard/helper/customCardHelper';

export default {
  name: 'CustomChatCard',
  components: {
    CustomCardButton,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    description: {
      type: String,
      default: '',
    },
    reason: {
      type: String,
      default: '',
    },
    mediaUrl: {
      type: String,
      default: '',
    },
    imageUrl: {
      type: String,
      default: '',
    },
    price: {
      type: String,
      default: '',
    },
    actions: {
      type: Array,
      default: () => [],
    },
    customFields: {
      type: Array,
      default: () => [],
    },
    supportsMarkdown: {
      type: Boolean,
      default: true,
    },
  },
  mounted() {
    console.log(`[CustomChatCard] Component mounted with title: ${this.title}`);
    console.log(`[CustomChatCard] Props:`, {
      title: this.title,
      description: this.description,
      mediaUrl: this.mediaUrl,
      imageUrl: this.imageUrl,
      price: this.price,
      reason: this.reason,
      actions: this.actions,
      customFields: this.customFields,
      supportsMarkdown: this.supportsMarkdown,
    });
    console.log(`[CustomChatCard] Image URL being used: ${this.mediaUrl || this.imageUrl}`);
  },
  methods: {
    renderMarkdown,
  },
};
</script>

<style lang="scss">
/* Using non-scoped styles for higher specificity */
.custom-chat-card {
  @apply transition-all duration-200 ease-in-out;
  @apply hover:shadow-md hover:scale-[1.02];
  border-radius: 0.5rem !important;
  overflow: hidden !important;
  width: 100% !important;
  max-width: 14rem !important;
  padding: 0 !important;
  margin: 0.5rem 0 !important;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1) !important;
  background-color: white !important;
  color: #1a202c !important; /* Ensure text is dark for readability */
  border: 1px solid #e2e8f0 !important;
  transition: transform 0.2s ease, box-shadow 0.2s ease !important;

  &.dark\:bg-slate-100 {
    background-color: #f8fafc !important; /* Light background in dark mode for readability */
  }

  &:hover {
    transform: translateY(-2px) !important;
    box-shadow: 0 8px 15px rgba(0, 0, 0, 0.1) !important;
  }

  &-image-container {
    position: relative !important;
    width: 100% !important;
    height: 150px !important;
    overflow: hidden !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    background-color: #f8fafc !important;
    border-radius: 5px 5px 0 0 !important;
  }

  &-image {
    width: 100% !important;
    object-fit: contain !important;
    max-height: 150px !important;
    display: block !important;
  }

  &-body {
    padding: 1rem !important;
    margin: 0 !important;
  }

  &-title {
    font-size: 1.5rem !important;
    font-weight: bold !important;
    text-align: center !important;
    margin: 0.5rem 0 1rem !important;
    line-height: 1.2 !important;
    color: #1a202c !important;
    overflow: hidden !important;
    text-overflow: ellipsis !important;
  }

  &-section {
    margin-bottom: 1rem !important;
    padding: 0.5rem !important;
    background-color: #f8fafc !important;
    border-radius: 0.25rem !important;
  }

  &-section-title {
    font-size: 1rem !important;
    font-weight: 600 !important;
    text-align: center !important;
    margin-bottom: 0.5rem !important;
    color: #4a5568 !important;
    padding-bottom: 0.25rem !important;
    border-bottom: 1px solid #e2e8f0 !important;
  }

  &-description, &-reason {
    font-size: 0.875rem !important;
    line-height: 1.4 !important;
    color: #2d3748 !important;
    text-align: left !important;
    margin-bottom: 0.5rem !important;
    word-break: break-word !important;
  }

  &-price {
    margin: 0.5rem 0 1rem !important;
    font-weight: bold !important;
    text-align: center !important;
    font-size: 1.5rem !important;
    line-height: 1.2 !important;
    color: #1a202c !important;
    padding: 0.5rem !important;
    background-color: #f0fff4 !important;
    border-radius: 0.25rem !important;
  }

  &-fields {
    margin-top: 1rem !important;
    padding-top: 1rem !important;
    border-top: 1px solid #e5e7eb !important;
  }

  &-field {
    display: flex !important;
    justify-content: space-between !important;
    align-items: center !important;
    margin-bottom: 0.5rem !important;
    
    &:last-child {
      margin-bottom: 0 !important;
    }
  }

  &-field-label {
    font-size: 0.875rem !important;
    font-weight: 500 !important;
    color: #4b5563 !important;
  }

  &-field-value {
    font-size: 0.875rem !important;
    color: #1a202c !important;
  }

  p {
    margin-bottom: 0.5rem !important;
    color: #2d3748 !important;
  }

  strong {
    font-weight: 600 !important;
  }

  em {
    font-style: italic !important;
  }

  :deep(ul), :deep(ol) {
    @apply pl-4 mb-2;
  }

  :deep(li) {
    @apply mb-1;
  }

  :deep(a) {
    @apply text-woot-500 dark:text-woot-400 hover:underline;
  }

  :deep(h1) {
    @apply text-2xl font-bold mb-2;
  }

  :deep(h2) {
    @apply text-xl font-bold mb-2;
  }

  :deep(h3) {
    @apply text-lg font-bold mb-2;
  }

  :deep(blockquote) {
    @apply border-l-4 border-slate-300 dark:border-slate-600 pl-4 italic;
  }

  :deep(code) {
    @apply bg-slate-100 dark:bg-slate-700 px-1 rounded;
  }

  :deep(pre) {
    @apply bg-slate-100 dark:bg-slate-700 p-2 rounded overflow-x-auto;
  }
}

.custom-chat-card-debug {
  border: 2px solid green !important;
  padding: 4px !important;
  margin: 8px 0 !important;
}
</style> 
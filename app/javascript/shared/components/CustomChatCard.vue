<template>
  <div class="custom-chat-card chat-bubble agent bg-white dark:bg-slate-100 max-w-56 rounded-lg overflow-hidden">
    <div v-if="displayUrl" class="custom-chat-card-image-container">
      <img class="custom-chat-card-image" :src="displayUrl" />
    </div>
    <div class="custom-chat-card-body">
      <h4 class="custom-chat-card-title" v-html="renderMarkdown(title, supportsMarkdown)"></h4>
      
      <div v-if="description" class="custom-chat-card-section">
        <h5 class="custom-chat-card-section-title">Product Description</h5>
        <p class="custom-chat-card-description" v-html="renderMarkdown(description, supportsMarkdown)"></p>
      </div>
      
      <div v-if="reason" class="custom-chat-card-section">
        <h5 class="custom-chat-card-section-title">Reason for Suggestion</h5>
        <p class="custom-chat-card-reason" v-html="renderMarkdown(reason, supportsMarkdown)"></p>
      </div>
      
      <p v-if="price" class="custom-chat-card-price" v-html="renderMarkdown(price, supportsMarkdown)"></p>
      
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
  computed: {
    displayUrl() {
      return this.imageUrl || this.mediaUrl || '';
    }
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

  &.dark\:bg-slate-100 {
    background-color: #f8fafc !important; /* Light background in dark mode for readability */
  }

  &-image-container {
    width: 100% !important;
    height: auto !important;
    max-height: 150px !important;
    overflow: hidden !important;
    display: block !important;
    margin: 0 !important;
    padding: 0 !important;
  }

  &-image {
    width: 100% !important;
    object-fit: contain !important;
    max-height: 150px !important;
    border-radius: 5px 5px 0 0 !important;
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
  }

  &-section {
    margin-bottom: 1rem !important;
  }

  &-section-title {
    font-size: 1rem !important;
    font-weight: 600 !important;
    text-align: center !important;
    margin-bottom: 0.5rem !important;
    color: #4a5568 !important;
  }

  &-description, &-reason {
    font-size: 0.875rem !important;
    line-height: 1.4 !important;
    color: #2d3748 !important;
    text-align: left !important;
    margin-bottom: 0.5rem !important;
  }

  &-price {
    margin: 0.5rem 0 1rem !important;
    font-weight: bold !important;
    text-align: center !important;
    font-size: 1.5rem !important;
    line-height: 1.2 !important;
    color: #1a202c !important;
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

  ul, ol {
    padding-left: 1rem !important;
    margin-bottom: 0.5rem !important;
  }

  li {
    margin-bottom: 0.25rem !important;
    color: #2d3748 !important;
  }

  a {
    color: #3182ce !important;
  }

  a:hover {
    text-decoration: underline !important;
  }

  h1, h2, h3, h4, h5, h6 {
    color: #1a202c !important;
  }

  blockquote {
    border-left: 4px solid #e2e8f0 !important;
    padding-left: 1rem !important;
    font-style: italic !important;
    color: #4a5568 !important;
  }

  code {
    background-color: #edf2f7 !important;
    padding: 0 0.25rem !important;
    border-radius: 0.25rem !important;
    color: #2d3748 !important;
  }

  pre {
    background-color: #edf2f7 !important;
    padding: 0.5rem !important;
    border-radius: 0.25rem !important;
    overflow-x: auto !important;
    color: #2d3748 !important;
  }
}
</style> 
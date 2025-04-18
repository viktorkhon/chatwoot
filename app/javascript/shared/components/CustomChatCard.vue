<template>
  <div class="custom-chat-card chat-bubble agent bg-white dark:bg-slate-800 max-w-56 rounded-lg overflow-hidden">
    <div v-if="displayUrl" class="custom-chat-card-image-container">
      <img class="custom-chat-card-image" :src="displayUrl" />
    </div>
    <div class="custom-chat-card-body">
      <h4 class="!text-base !font-medium !mt-1 !mb-1 !leading-[1.5] text-slate-900 dark:text-slate-100">
        {{ title }}
      </h4>
      <p class="!mb-1 text-slate-700 dark:text-slate-300">
        {{ description }}
      </p>
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

  &.dark\:bg-slate-800 {
    background-color: #1e293b !important;
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

  &-price {
    margin-bottom: 0.5rem !important;
    font-weight: bold !important;
    text-align: center !important;
    font-size: 1.5rem !important;
    line-height: 1.2 !important;
    color: #111827 !important;
  }

  .dark &-price {
    color: #f9fafb !important;
  }

  &-fields {
    margin-top: 1rem !important;
    padding-top: 1rem !important;
    border-top: 1px solid #e5e7eb !important;
  }

  .dark &-fields {
    border-top-color: #374151 !important;
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

  .dark &-field-label {
    color: #9ca3af !important;
  }

  &-field-value {
    font-size: 0.875rem !important;
    color: #111827 !important;
  }

  .dark &-field-value {
    color: #f9fafb !important;
  }

  p {
    margin-bottom: 0.5rem !important;
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
  }

  a {
    color: var(--woot-500) !important;
  }

  .dark a {
    color: var(--woot-400) !important;
  }

  a:hover {
    text-decoration: underline !important;
  }

  h1 {
    font-size: 1.5rem !important;
    font-weight: 700 !important;
    margin-bottom: 0.5rem !important;
  }

  h2 {
    font-size: 1.25rem !important;
    font-weight: 700 !important;
    margin-bottom: 0.5rem !important;
  }

  h3 {
    font-size: 1.125rem !important;
    font-weight: 700 !important;
    margin-bottom: 0.5rem !important;
  }

  blockquote {
    border-left: 4px solid #d1d5db !important;
    padding-left: 1rem !important;
    font-style: italic !important;
  }

  .dark blockquote {
    border-left-color: #4b5563 !important;
  }

  code {
    background-color: #f3f4f6 !important;
    padding: 0 0.25rem !important;
    border-radius: 0.25rem !important;
  }

  .dark code {
    background-color: #374151 !important;
  }

  pre {
    background-color: #f3f4f6 !important;
    padding: 0.5rem !important;
    border-radius: 0.25rem !important;
    overflow-x: auto !important;
  }

  .dark pre {
    background-color: #374151 !important;
  }
}
</style> 
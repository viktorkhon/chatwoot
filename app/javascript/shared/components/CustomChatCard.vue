<template>
  <div class="custom-chat-card chat-bubble agent bg-white dark:bg-slate-800 max-w-56 rounded-lg overflow-hidden">
    <img v-if="displayUrl" class="w-full object-contain max-h-[150px] rounded-[5px]" :src="displayUrl" />
    <div class="custom-chat-card-body">
      <h4 class="!text-base !font-medium !mt-1 !mb-1 !leading-[1.5] text-slate-900 dark:text-slate-100">
        {{ title }}
      </h4>
      <p class="!mb-1 text-slate-700 dark:text-slate-300">
        {{ description }}
      </p>
      <p v-if="price" class="!mb-2 font-bold text-center text-2xl text-slate-900 dark:text-slate-100" v-html="renderMarkdown(price, supportsMarkdown)"></p>
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

<style lang="scss" scoped>
.custom-chat-card {
  @apply transition-all duration-200 ease-in-out;
  @apply hover:shadow-md hover:scale-[1.02];

  &-body {
    @apply p-4;
  }

  &-fields {
    @apply mt-4 pt-4 border-t border-slate-200 dark:border-slate-700;
  }

  &-field {
    @apply flex justify-between items-center mb-2 last:mb-0;
  }

  &-field-label {
    @apply text-sm font-medium text-slate-600 dark:text-slate-400;
  }

  &-field-value {
    @apply text-sm text-slate-900 dark:text-slate-100;
  }

  :deep(p) {
    @apply mb-2;
  }

  :deep(strong) {
    @apply font-semibold;
  }

  :deep(em) {
    @apply italic;
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
</style> 
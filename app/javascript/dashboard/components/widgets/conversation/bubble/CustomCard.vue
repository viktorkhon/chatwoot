<template>
  <div class="card-container">
    <div v-for="(item, index) in items" :key="index" class="card">
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
    console.log(`[CustomCard.vue] Mounted. Received items prop:`, JSON.parse(JSON.stringify(this.items)));
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
  @apply flex flex-col gap-4;
}

.card {
  @apply bg-white dark:bg-slate-800 rounded-lg overflow-hidden shadow-sm max-w-[20rem];
}

.card-media {
  @apply relative;
}

.card-image {
  @apply w-full h-48 object-cover;
}

.card-content {
  @apply p-4;
}

.card-title {
  @apply text-base font-semibold text-slate-900 dark:text-slate-100 mb-2;
}

.card-reason {
  @apply bg-slate-50 dark:bg-slate-700 p-3 rounded-md mb-3;
}

.card-reason-title {
  @apply text-sm font-medium text-slate-700 dark:text-slate-200 mb-1;
}

.card-reason-content {
  @apply text-sm text-slate-600 dark:text-slate-300;
}

.card-description {
  @apply text-sm text-slate-600 dark:text-slate-300 mb-4;

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

.card-price {
  @apply text-base font-semibold text-slate-900 dark:text-slate-100 text-center mb-3;

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

.card-actions {
  @apply flex flex-wrap gap-2;
}

.card-action-button {
  @apply px-3 py-1.5 text-sm rounded-md transition-colors duration-200;
  @apply bg-slate-100 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600;
  @apply text-slate-700 dark:text-slate-200;

  &.is-link {
    @apply bg-woot-100 hover:bg-woot-200 dark:bg-woot-900 dark:hover:bg-woot-800;
    @apply text-woot-700 dark:text-woot-200;
  }

  &.is-postback {
    @apply bg-green-100 hover:bg-green-200 dark:bg-green-900 dark:hover:bg-green-800;
    @apply text-green-700 dark:text-green-200;
  }
}
</style> 
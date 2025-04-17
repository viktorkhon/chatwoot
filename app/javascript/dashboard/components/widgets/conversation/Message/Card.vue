<template>
  <div class="card-container">
    <div v-for="(item, index) in items" :key="index" class="card-item">
      <div v-if="item.image_url" class="card-image">
        <img :src="item.image_url" :alt="item.title" />
      </div>
      <div class="card-content">
        <h3 v-if="item.title">{{ item.title }}</h3>
        <p v-if="item.description" v-html="item.description"></p>
        <p v-if="item.price" class="price">{{ item.price }}</p>
        <div v-if="item.actions" class="card-actions">
          <button
            v-for="(action, actionIndex) in item.actions"
            :key="actionIndex"
            @click="handleAction(action)"
            class="action-button"
          >
            {{ action.text }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  name: 'Card',
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    items() {
      return this.message.content_attributes?.items || [];
    },
  },
  methods: {
    handleAction(action) {
      this.$bus.$emit(BUS_EVENTS.CUSTOM_CARD_ACTION, {
        messageId: this.message.id,
        action,
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.card-container {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1rem;
}

.card-item {
  border: 1px solid var(--color-border);
  border-radius: 8px;
  overflow: hidden;
}

.card-image {
  width: 100%;
  height: 200px;
  overflow: hidden;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}

.card-content {
  padding: 1rem;

  h3 {
    margin: 0 0 0.5rem;
    font-size: 1.1rem;
    font-weight: 600;
  }

  p {
    margin: 0.5rem 0;
  }

  .price {
    font-weight: 600;
    color: var(--color-primary);
  }
}

.card-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
}

.action-button {
  padding: 0.5rem 1rem;
  border: 1px solid var(--color-border);
  border-radius: 4px;
  background: var(--color-background);
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background: var(--color-background-light);
  }
}
</style> 
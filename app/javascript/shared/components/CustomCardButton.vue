<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import { IFrameHelper } from 'widget/helpers/utils';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { sendMessageAPI } from 'widget/api/conversation';

export default {
  props: {
    action: {
      type: Object,
      default: () => {},
    },
  },
  mounted() {
    // Debug log to check configuration on component mount
    console.log('CustomCardButton mounted with:');
    console.log('- window.chatwootConfig:', window.chatwootConfig);
    console.log('- n8n URL:', window.chatwootConfig?.n8nRetrieveProductUrl);
    console.log('- Action:', this.action);
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    isLink() {
      return this.action.type === 'link';
    },
    isPostback() {
      return this.action.type === 'postback';
    },
    isCustom() {
      return this.action.type === 'custom';
    },
  },
  methods: {
    onClick() {
      if (this.isPostback) {
        // Get the n8n webhook URL from the config
        const n8nProductInfoUrl = window.chatwootConfig?.n8nRetrieveProductUrl;
        
        if (!n8nProductInfoUrl) {
          console.warn('⚠️ Webhook URL is missing in window.chatwootConfig.n8nRetrieveProductUrl');
        }
        
        // Prepare payload - handle both string and object cases
        let productData;
        if (typeof this.action.payload === 'string') {
          // If payload is a string, use it as both ID and name
          productData = {
            product_id: this.action.payload,
            product_name: this.action.payload
          };
        } else if (this.action.payload?.product_data) {
          // If payload has explicit product_data object
          productData = this.action.payload.product_data;
        } else if (typeof this.action.payload === 'object' && this.action.payload !== null) {
          // If payload is an object, use it directly
          productData = this.action.payload;
        }
        
        if (productData) {
          console.log('📦 Product data:', JSON.stringify(productData, null, 2));
          
          // Create a standard user message when product is selected
          this.sendProductInfoMessage(productData, n8nProductInfoUrl);
        }
        
        // Standard iframe postback behavior (keep original functionality)
        if (IFrameHelper.isIFrame()) {
          IFrameHelper.sendMessage({
            event: 'postback',
            data: { payload: this.action.payload },
          });
        } else {
          // If not in iframe, emit the event locally
          emitter.emit(BUS_EVENTS.CUSTOM_CARD_ACTION, {
            action: this.action,
            card: this.$parent.$props,
          });
        }
      } else if (this.isCustom) {
        emitter.emit(BUS_EVENTS.CUSTOM_CARD_ACTION, {
          action: this.action,
          card: this.$parent.$props,
        });
      }
    },
    sendProductInfoMessage(productData, targetUrl) {
      // Format a user-friendly message but include the product data
      // The 'product_data' field in content_attributes will be available in webhooks
      const content = `Show me more Details for ': ${productData.product_name || productData.product_id}`;
      
      // Check if we're in the widget context with Vuex store
      if (this.$store && this.$store.dispatch) {
        // Use the store to send the message
        this.$store.dispatch('conversation/sendMessage', {
          content: content,
          contentAttributes: {
            product_data: productData,
            target_webhook: targetUrl
          }
        }).then(() => {
          console.log('✅ Message sent successfully');
        }).catch(error => {
          console.error('❌ Error sending message:', error);
        });
      } else {
        // Fall back to direct API call without store
        try {
          sendMessageAPI(content, null).then(() => {
            console.log('✅ Message sent successfully');
          }).catch(error => {
            console.error('❌ Error sending message:', error);
          });
        } catch (error) {
          console.error('❌ Error sending message:', error);
        }
      }
    }
  },
};
</script>

<template>
  <a
    v-if="isLink"
    :key="action.uri"
    class="custom-action-button button"
    :href="action.uri"
    :style="{
      background: widgetColor,
      borderColor: widgetColor,
      color: textColor,
    }"
    target="_blank"
    rel="noopener nofollow noreferrer"
  >
    {{ action.text }}
  </a>
  <button
    v-else
    type="button"
    :key="action.payload"
    class="custom-action-button button"
    :class="{
      '!bg-n-background dark:!bg-n-alpha-black1 text-woot-500': !isCustom,
      '!bg-purple-100 dark:!bg-purple-900 text-purple-700 dark:text-purple-200': isCustom,
    }"
    :style="{ borderColor: widgetColor, color: widgetColor }"
    @click="onClick"
  >
    {{ action.text }}
  </button>
</template>

<style scoped lang="scss">
.custom-action-button {
  @apply items-center rounded-lg flex font-medium justify-center mt-1 p-0 w-full;
  @apply transition-colors duration-200;
}
</style> 
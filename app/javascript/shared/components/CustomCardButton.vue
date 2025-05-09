<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import { IFrameHelper } from 'widget/helpers/utils';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  props: {
    action: {
      type: Object,
      default: () => {},
    },
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
        // Process n8n webhook if configured
        const n8nProductInfoUrl = window.chatwootConfig?.n8nRetrieveProductUrl;
        
        if (!n8nProductInfoUrl) {
          console.warn('⚠️ Webhook URL is missing in window.chatwootConfig.n8nRetrieveProductUrl');
        }
        
        if (n8nProductInfoUrl) {
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
            // Log exact URL and data being sent
            console.log('🔗 Webhook URL:', n8nProductInfoUrl);
            console.log('📦 Sending data:', JSON.stringify(productData, null, 2));
            
            // Make the actual API call to n8n
            fetch(n8nProductInfoUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(productData)
            })
            .then(response => {
              if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
              }
              console.log('✅ Webhook response status:', response.status);
              return response.json();
            })
            .then(data => {
              // Emit event with response data if needed
              console.log('📬 Webhook response data:', data);
              emitter.emit(BUS_EVENTS.N8N_RESPONSE_RECEIVED, data);
            })
            .catch(error => {
              console.error('❌ Error calling n8n webhook:', error.message);
            });
          }
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
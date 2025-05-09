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
  data() {
    return {
      isDebug: process.env.NODE_ENV !== 'production',
    };
  },
  mounted() {
    if (this.isDebug) {
      console.log('CustomCardButton mounted. Action:', JSON.parse(JSON.stringify(this.action)));
    }
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
      console.log('🔴 BUTTON CLICKED: CustomCardButton.onClick() called with action:', 
                 JSON.parse(JSON.stringify(this.action)));
                 
      if (this.isPostback) {
        console.log('📱 Handling postback action: ', this.action.text);
        
        // Try to get n8n URL from window config
        const n8nProductInfoUrl = window.chatwootConfig?.n8nRetrieveProductUrl;
        console.log('🌐 N8N URL:', n8nProductInfoUrl);
        
        // Check if we have the n8n webhook URL configured
        if (n8nProductInfoUrl) {
          console.log('✅ N8N URL found. Processing webhook call...');
          
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
          } else {
            console.warn('⚠️ No usable product data in payload');
          }
          
          if (productData) {
            console.log('📦 Sending data to n8n:', productData);
            
            // Make the actual API call to n8n
            fetch(n8nProductInfoUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(productData)
            })
            .then(response => {
              console.log(`📣 n8n response status: ${response.status}`);
              if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
              }
              return response.json();
            })
            .then(data => {
              console.log('🎉 n8n response data:', data);
              // Emit event with response data if needed
              emitter.emit('N8N_RESPONSE_RECEIVED', data);
            })
            .catch(error => {
              console.error('❌ Error calling n8n webhook:', error);
            });
          }
        }
        
        // Send message to parent iframe (original behavior)
        if (IFrameHelper.isIFrame()) {
          console.log('📤 Sending postback to parent iframe');
          IFrameHelper.sendMessage({
            event: 'postback',
            data: { payload: this.action.payload },
          });
        } else {
          console.log('🔄 Not in iframe, emitting CUSTOM_CARD_ACTION event');
          // If not in iframe, emit the event locally (for dashboard view)
          emitter.emit(BUS_EVENTS.CUSTOM_CARD_ACTION || 'CUSTOM_CARD_ACTION', {
            action: this.action,
            card: this.$parent.$props,
          });
        }
      } else if (this.isCustom) {
        console.log('🔧 Handling custom action type');
        emitter.emit(BUS_EVENTS.CUSTOM_CARD_ACTION || 'CUSTOM_CARD_ACTION', {
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
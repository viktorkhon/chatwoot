<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { CONTENT_TYPES } from 'shared/constants/contentType';
import ChatCard from 'shared/components/ChatCard.vue';
import ChatForm from 'shared/components/ChatForm.vue';
import ChatOptions from 'shared/components/ChatOptions.vue';
import ChatArticle from './template/Article.vue';
import EmailInput from './template/EmailInput.vue';
import CustomerSatisfaction from 'shared/components/CustomerSatisfaction.vue';
import IntegrationCard from './template/IntegrationCard.vue';
import CustomChatCard from 'shared/components/CustomChatCard.vue';

export default {
  name: 'AgentMessageBubble',
  components: {
    ChatArticle,
    ChatCard,
    ChatForm,
    ChatOptions,
    EmailInput,
    CustomerSatisfaction,
    IntegrationCard,
    CustomChatCard,
  },
  props: {
    message: { type: String, default: null },
    contentType: { type: String, default: null },
    messageType: { type: Number, default: null },
    messageId: { type: Number, default: null },
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
  },
  setup() {
    const { formatMessage, getPlainText, truncateMessage, highlightContent } =
      useMessageFormatter();
    return {
      formatMessage,
      getPlainText,
      truncateMessage,
      highlightContent,
    };
  },
  computed: {
    isTemplate() {
      return this.messageType === 3;
    },
    isTemplateEmail() {
      return this.contentType === 'input_email';
    },
    isCards() {
      return this.contentType === CONTENT_TYPES.CARDS;
    },
    isOptions() {
      return this.contentType === 'input_select';
    },
    isForm() {
      return this.contentType === CONTENT_TYPES.FORM;
    },
    isArticle() {
      return this.contentType === 'article';
    },
    isCSAT() {
      return this.contentType === 'input_csat';
    },
    isIntegrations() {
      return this.contentType === 'integrations';
    },
    isCustomCards() {
      const result = this.contentType === 'custom_cards';
      console.log(`[AgentMessageBubble] isCustomCards check for message ID ${this.messageId}: ${result}, contentType: ${this.contentType}`);
      return result;
    },
  },
  mounted() {
    console.log(`[AgentMessageBubble] Component mounted for message ID: ${this.messageId}, contentType: ${this.contentType}`);
    console.log(`[AgentMessageBubble] All props received:`, {
      contentType: this.contentType,
      messageId: this.messageId,
      messageType: this.messageType,
      messageContentAttributes: this.messageContentAttributes,
      message: this.message
    });
    
    if (this.contentType === 'custom_cards') {
      console.log(`[AgentMessageBubble] Custom card message content attributes:`, this.messageContentAttributes);
      console.log(`[AgentMessageBubble] Custom card items:`, this.messageContentAttributes.items);
      
      if (!this.messageContentAttributes.items || this.messageContentAttributes.items.length === 0) {
        console.warn('[AgentMessageBubble] No items found in custom cards. This is likely why they are not displaying.');
      } else {
        console.log('[AgentMessageBubble] Items found in custom cards:', this.messageContentAttributes.items.length);
        console.log('[AgentMessageBubble] First item details:', this.messageContentAttributes.items[0]);
      }
    }
  },
  methods: {
    onResponse(messageResponse) {
      this.$store.dispatch('message/update', messageResponse);
    },
    onOptionSelect(selectedOption) {
      this.onResponse({
        submittedValues: [selectedOption],
        messageId: this.messageId,
      });
    },
    onFormSubmit(formValues) {
      const formValuesAsArray = Object.keys(formValues).map(key => ({
        name: key,
        value: formValues[key],
      }));
      this.onResponse({
        submittedValues: formValuesAsArray,
        messageId: this.messageId,
      });
    },
  },
};
</script>

<template>
  <div class="chat-bubble-wrap">
    <div
      v-if="
        !isCards && !isOptions && !isForm && !isArticle && !isCSAT && !isCustomCards
      "
      class="chat-bubble agent bg-n-background dark:bg-n-solid-3 text-n-slate-12"
    >
      <div
        v-dompurify-html="formatMessage(message, false)"
        class="message-content text-n-slate-12"
      />
      <EmailInput
        v-if="isTemplateEmail"
        :message-id="messageId"
        :message-content-attributes="messageContentAttributes"
      />

      <IntegrationCard
        v-if="isIntegrations"
        :message-id="messageId"
        :meeting-data="messageContentAttributes.data"
      />
    </div>
    <div v-if="isOptions">
      <ChatOptions
        :title="message"
        :options="messageContentAttributes.items"
        :hide-fields="!!messageContentAttributes.submitted_values"
        @option-select="onOptionSelect"
      />
    </div>
    <ChatForm
      v-if="isForm && !messageContentAttributes.submitted_values"
      :items="messageContentAttributes.items"
      :button-label="messageContentAttributes.button_label"
      :submitted-values="messageContentAttributes.submitted_values"
      @submit="onFormSubmit"
    />
    <div v-if="isCards">
      <ChatCard
        v-for="item in messageContentAttributes.items"
        :key="item.title"
        :media-url="item.media_url"
        :title="item.title"
        :description="item.description"
        :actions="item.actions"
      />
    </div>
    <div v-if="isArticle">
      <ChatArticle :items="messageContentAttributes.items" />
    </div>
    <CustomerSatisfaction
      v-if="isCSAT"
      :message-content-attributes="messageContentAttributes.submitted_values"
      :message-id="messageId"
    />
    <div v-if="content_type === 'custom_cards'" class="custom-cards-container" style="border: 4px solid red !important; padding: 8px !important; margin: 12px 0 !important;">
      <div class="debug-info p-2 mb-2 bg-red-100 border border-red-400 text-red-800" style="display: block !important;">
        Debug: AgentMessageBubble rendering CustomChatCards - #items: {{messageContentAttributes.items?.length}}
      </div>
      <div v-if="messageContentAttributes.items && messageContentAttributes.items.length > 0">
        <div style="color: black; background: white; padding: 8px; margin-bottom: 8px; border: 2px dotted blue;">
          Data exists but cards might be hidden. Items count: {{messageContentAttributes.items.length}}
        </div>
        
        <!-- Regular card rendering -->
        <CustomChatCard
          v-for="(item, index) in messageContentAttributes.items"
          :key="item.title || index"
          :media-url="item.image_url || item.media_url"
          :image-url="item.image_url || item.media_url"
          :title="item.title"
          :description="item.description"
          :price="item.price"
          :reason="item.reason"
          :actions="item.actions"
          :custom-fields="item.custom_fields"
          :supports-markdown="item.supports_markdown"
          style="display: block !important; visibility: visible !important; opacity: 1 !important; margin: 10px 0 !important; border: 3px solid green !important;"
        />
        
        <!-- Fallback rendering if cards don't appear -->
        <div style="margin-top: 20px; padding: 10px; background: #ffffcc; border: 2px dashed orange; color: black;">
          <h3 style="font-weight: bold; margin-bottom: 10px;">Fallback Cards Display:</h3>
          <div v-for="(item, index) in messageContentAttributes.items" :key="'fallback-'+index" 
               style="margin-bottom: 15px; padding: 10px; border: 1px solid #ccc; background: white;">
            <p><strong>Product:</strong> {{item.title}}</p>
            <p v-if="item.image_url"><img :src="item.image_url" style="max-width: 100px; max-height: 100px; object-fit: contain;" /></p>
            <p v-if="item.description"><strong>Description:</strong> {{item.description}}</p>
            <p v-if="item.price"><strong>Price:</strong> {{item.price}}</p>
            <div v-if="item.actions && item.actions.length">
              <strong>Actions:</strong>
              <div v-for="(action, actionIndex) in item.actions" :key="'action-'+actionIndex" 
                   style="margin: 5px; padding: 5px; background: #eee;">
                {{action.text || action.label || 'Action '+actionIndex}}
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-else class="text-red-500 p-2" style="background: yellow; display: block !important;">
        No items found in custom cards data. Check console logs.
      </div>
    </div>
  </div>
</template>

<style lang="scss">
.custom-cards-container {
  display: flex !important;
  flex-direction: column !important;
  align-items: flex-start !important;
  width: 100% !important;
  margin: 12px 0 !important;
  padding: 8px !important;
  position: relative !important;
  z-index: 1000 !important;
  min-height: 100px !important;
  background-color: rgba(255, 255, 255, 0.1) !important;
  border: 3px solid purple !important;
}
</style>

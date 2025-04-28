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
    if (this.contentType === 'custom_cards') {
      console.log(`[AgentMessageBubble] Custom card message content attributes:`, this.messageContentAttributes);
      console.log(`[AgentMessageBubble] Custom card items:`, this.messageContentAttributes.items);
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
        !isCards && !isOptions && !isForm && !isArticle && !isCards && !isCSAT && !isCustomCards
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
    <div v-if="isCustomCards" class="custom-cards-container">
      <CustomChatCard
        v-for="item in messageContentAttributes.items"
        :key="item.title"
        :media-url="item.image_url"
        :image-url="item.image_url"
        :title="item.title"
        :description="item.description"
        :price="item.price"
        :reason="item.reason"
        :actions="item.actions"
        :custom-fields="item.custom_fields"
        :supports-markdown="item.supports_markdown"
      />
      <p class="debug-placeholder" style="display:none;">Custom cards visible</p>
    </div>
    <div v-else-if="contentType === 'custom_cards'" class="text-red-500 p-2">
      Custom cards should appear here but condition failed. Check console logs.
    </div>
  </div>
</template>

<style lang="scss">
.custom-cards-container {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  width: 100%;
  margin: 0;
  padding: 0;
}
</style>

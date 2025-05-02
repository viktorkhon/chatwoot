// This file has the same name, but is used specifically to control how messages are displayed
// on the Agent dashboard view. The other file is used for the User Conversation view.
<script setup>
import { defineProps, computed } from 'vue';
import Message from './Message.vue';
import { MESSAGE_TYPES } from './constants.js';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';

/**
 * Props definition for the component
 * @typedef {Object} Props
 * @property {Array} readMessages - Array of read messages
 * @property {Array} unReadMessages - Array of unread messages
 * @property {Number} currentUserId - ID of the current user
 * @property {Boolean} isAnEmailChannel - Whether this is an email channel
 * @property {Object} inboxSupportsReplyTo - Inbox reply support configuration
 * @property {Array} messages - Array of all messages [These are not in camelcase]
 */
const props = defineProps({
  currentUserId: {
    type: Number,
    required: true,
  },
  firstUnreadId: {
    type: Number,
    default: null,
  },
  isAnEmailChannel: {
    type: Boolean,
    default: false,
  },
  inboxSupportsReplyTo: {
    type: Object,
    default: () => ({ incoming: false, outgoing: false }),
  },
  messages: {
    type: Array,
    default: () => [],
  },
});

const allMessages = computed(() => {
  // First transform all messages to camelCase
  const camelCasedMessages = useCamelCase(props.messages, { deep: true });
  
  // For custom_cards type messages, ensure we preserve the original content_attributes
  // This specialized handling is needed because the CustomCardsBubble component
  // expects to find the 'items' array in the original content_attributes structure,
  // but the camelCase transformation may cause the structure to be different.
  return camelCasedMessages.map(message => {
    // Check if this is a custom_cards message type (in either case format)
    if (message.contentType === 'custom_cards' || message.content_type === 'custom_cards') {
      // Find the original message to get its content_attributes
      const originalMessage = props.messages.find(m => m.id === message.id);
      
      if (originalMessage && originalMessage.content_attributes) {
        // For custom cards, we need to preserve both formats:
        // 1. The camelCase version (contentAttributes) for standard Vue props
        // 2. The snake_case version (content_attributes) for components that expect the original format
        return {
          ...message,
          content_attributes: originalMessage.content_attributes
        };
      }
    }
    return message;
  });
});

/**
 * Determines if a message should be grouped with the next message
 * @param {Number} index - Index of the current message
 * @param {Array} searchList - Array of messages to check
 * @returns {Boolean} - Whether the message should be grouped with next
 */
const shouldGroupWithNext = (index, searchList) => {
  if (index === searchList.length - 1) return false;

  const current = searchList[index];
  const next = searchList[index + 1];

  if (next.status === 'failed') return false;

  const nextSenderId = next.senderId ?? next.sender?.id;
  const currentSenderId = current.senderId ?? current.sender?.id;
  const hasSameSender = nextSenderId === currentSenderId;

  const nextMessageType = next.messageType;
  const currentMessageType = current.messageType;

  const areBothTemplates =
    nextMessageType === MESSAGE_TYPES.TEMPLATE &&
    currentMessageType === MESSAGE_TYPES.TEMPLATE;

  if (!hasSameSender || areBothTemplates) return false;

  if (currentMessageType !== nextMessageType) return false;

  // Check if messages are in the same minute by rounding down to nearest minute
  return Math.floor(next.createdAt / 60) === Math.floor(current.createdAt / 60);
};

/**
 * Gets the message that was replied to
 * @param {Object} parentMessage - The message containing the reply reference
 * @returns {Object|null} - The message being replied to, or null if not found
 */
const getInReplyToMessage = parentMessage => {
  if (!parentMessage) return null;

  const inReplyToMessageId =
    parentMessage.contentAttributes?.inReplyTo ??
    parentMessage.content_attributes?.in_reply_to;

  if (!inReplyToMessageId) return null;

  // Find in-reply-to message in the messages prop
  const replyMessage = props.messages?.find(
    message => message.id === inReplyToMessageId
  );

  return replyMessage ? useCamelCase(replyMessage) : null;
};
</script>

<template>
  <ul class="px-4 bg-n-background">
    <slot name="beforeAll" />
    <template v-for="(message, index) in allMessages" :key="message.id">
      <slot
        v-if="firstUnreadId && message.id === firstUnreadId"
        name="unreadBadge"
      />
      <Message
        v-bind="message"
        :is-email-inbox="isAnEmailChannel"
        :in-reply-to="getInReplyToMessage(message)"
        :group-with-next="shouldGroupWithNext(index, allMessages)"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :current-user-id="currentUserId"
        data-clarity-mask="True"
      />
    </template>
    <slot name="after" />
  </ul>
</template>

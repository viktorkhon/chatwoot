import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';
import { playNewMessageNotificationInWidget } from 'widget/helpers/WidgetAudioNotificationHelper';
import { ON_AGENT_MESSAGE_RECEIVED } from '../constants/widgetBusEvents';
import { IFrameHelper } from 'widget/helpers/utils';
import { shouldTriggerMessageUpdateEvent } from './IframeEventHelper';
import { CHATWOOT_ON_MESSAGE } from '../constants/sdkEvents';
import { emitter } from '../../shared/helpers/mitt';

const isMessageInActiveConversation = (getters, message) => {
  const { conversation_id: conversationId } = message;
  const activeConversationId =
    getters['conversationAttributes/getConversationParams'].id;
  return activeConversationId && conversationId !== activeConversationId;
};

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    super(app, pubsubToken);
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
      'conversation.status_changed': this.onStatusChange,
      'conversation.created': this.onConversationCreated,
      'presence.update': this.onPresenceUpdate,
      'contact.merged': this.onContactMerge,
    };
  }

  onDisconnected = () => {
    this.setLastMessageId();
  };

  onReconnect = () => {
    this.syncLatestMessages();
  };

  setLastMessageId = () => {
    this.app.$store.dispatch('conversation/setLastMessageId');
  };

  syncLatestMessages = () => {
    this.app.$store.dispatch('conversation/syncLatestMessages');
  };

  onStatusChange = data => {
    if (data.status === 'resolved') {
      this.app.$store.dispatch('campaign/resetCampaign');
    }
    this.app.$store.dispatch('conversationAttributes/update', data);
  };

  onMessageCreated = data => {
    if (isMessageInActiveConversation(this.app.$store.getters, data)) {
      return;
    }

    this.app.$store
      .dispatch('conversation/addOrUpdateMessage', data)
      .then(() => emitter.emit(ON_AGENT_MESSAGE_RECEIVED));

    IFrameHelper.sendMessage({
      event: 'onEvent',
      eventIdentifier: CHATWOOT_ON_MESSAGE,
      data,
    });
    if (data.sender_type === 'User') {
      playNewMessageNotificationInWidget();
    }
  };

  onMessageUpdated = data => {
    if (isMessageInActiveConversation(this.app.$store.getters, data)) {
      return;
    }

    if (shouldTriggerMessageUpdateEvent(data)) {
      IFrameHelper.sendMessage({
        event: 'onEvent',
        eventIdentifier: CHATWOOT_ON_MESSAGE,
        data,
      });
    }

    this.app.$store.dispatch('conversation/addOrUpdateMessage', data);
  };

  onConversationCreated = () => {
    this.app.$store.dispatch('conversationAttributes/getAttributes');
  };

  onPresenceUpdate = data => {
    this.app.$store.dispatch('agent/updatePresence', data.users);
  };

  // eslint-disable-next-line class-methods-use-this
  onContactMerge = data => {
    const { pubsub_token: pubsubToken } = data;
    ActionCableConnector.refreshConnector(pubsubToken);
  };

  onTypingOn = data => {
    const activeConversationId =
      this.app.$store.getters['conversationAttributes/getConversationParams']
        .id;
    const conversationAttributes = 
      this.app.$store.getters['conversationAttributes/getConversationParams'];
    const isUserTypingOnAnotherConversation =
      data.conversation && data.conversation.id !== activeConversationId;

    if (isUserTypingOnAnotherConversation || data.is_private) {
      return;
    }

    // Get the conversation's status and assignment information
    const { assignee, team } = conversationAttributes;
    const isAssignedToAgentOrTeam = assignee || team;
    
    // Check if typing event is from an automated source (bot, automation system, etc.)
    const isAutomatedSource = data.user && (
      data.user.bot || 
      data.user.type === 'automation' || 
      data.user.type === 'agent_bot' ||
      data.source_type === 'bot' ||
      data.source_type === 'automation'
    );
    
    // Get the last message's sender type - In Chatwoot:
    // message_type = 0 (INCOMING) means message from agent/bot to user
    // message_type = 1 (OUTGOING) means message from user to agent/bot
    const lastMessage = this.app.$store.getters['conversation/getLastMessage'];
    const isLastMessageFromUser = lastMessage && lastMessage.message_type === 1;
    
    // Check if the last message was sent very recently (within the last 2 seconds)
    // This helps prevent automated typing indicators from appearing right after a user message
    const lastMessageTimestamp = lastMessage && lastMessage.created_at;
    const currentTime = Date.now() / 1000; // Convert to seconds
    const isRecentUserMessage = isLastMessageFromUser && 
      lastMessageTimestamp && 
      (currentTime - lastMessageTimestamp < 2);
    
    // CASE 1: If conversation is assigned to agent/team AND typing event is from an automated source,
    // don't show the typing indicator at all
    if (isAssignedToAgentOrTeam && isAutomatedSource) {
      return;
    }
    
    // CASE 2: If the last message was from the user and was very recent,
    // AND the typing event comes immediately after (likely automated),
    // don't show typing indicator if conversation is assigned
    if (isRecentUserMessage && isAssignedToAgentOrTeam) {
      // Only show typing from the actual assigned agent
      const isAssignedAgentTyping = assignee && data.user && data.user.id === assignee.id;
      if (!isAssignedAgentTyping) {
        return;
      }
    }
    
    // For unassigned conversations or real agent typing, show the indicator
    this.clearTimer();
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'on',
    });
    this.initTimer();
  };

  onTypingOff = () => {
    this.clearTimer();
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'off',
    });
  };

  clearTimer = () => {
    if (this.CancelTyping) {
      clearTimeout(this.CancelTyping);
      this.CancelTyping = null;
    }
  };

  initTimer = () => {
    // Turn off typing automatically after 30 seconds
    this.CancelTyping = setTimeout(() => {
      this.onTypingOff();
    }, 30000);
  };
}

export default ActionCableConnector;

<script>
import { ref, nextTick } from 'vue';
// composable
import { useConfig } from 'dashboard/composables/useConfig';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useAI } from 'dashboard/composables/useAI';
import { useMapGetter } from 'dashboard/composables/store';

// components
import ReplyBox from './ReplyBox.vue';
import Message from './Message.vue';
import NextMessageList from 'next/message/MessageList.vue';
import ConversationLabelSuggestion from './conversation/LabelSuggestion.vue';
import Banner from 'dashboard/components/ui/Banner.vue';
import CustomCard from '../conversation/bubble/CustomCard.vue';

// stores and apis
import { mapGetters } from 'vuex';

// mixins
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';

// utils
import { emitter } from 'shared/helpers/mitt';
import { getTypingUsersText } from '../../../helper/commons';
import { calculateScrollTop } from './helpers/scrollTopCalculationHelper';
import { LocalStorage } from 'shared/helpers/localStorage';
import {
  filterDuplicateSourceMessages,
  getReadMessages,
  getUnreadMessages,
} from 'dashboard/helper/conversationHelper';

// constants
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { REPLY_POLICY } from 'shared/constants/links';
import wootConstants from 'dashboard/constants/globals';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { FEATURE_FLAGS } from '../../../featureFlags';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Message,
    NextMessageList,
    ReplyBox,
    Banner,
    ConversationLabelSuggestion,
    NextButton,
    CustomCard,
  },
  mixins: [inboxMixin],
  props: {
    isContactPanelOpen: {
      type: Boolean,
      default: false,
    },
    isInboxView: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['contactPanelToggle'],
  setup() {
    const isPopOutReplyBox = ref(false);
    const { isEnterprise } = useConfig();

    const closePopOutReplyBox = () => {
      isPopOutReplyBox.value = false;
    };

    const showPopOutReplyBox = () => {
      isPopOutReplyBox.value = !isPopOutReplyBox.value;
    };

    const keyboardEvents = {
      Escape: {
        action: closePopOutReplyBox,
      },
    };

    useKeyboardEvents(keyboardEvents);

    const {
      isAIIntegrationEnabled,
      isLabelSuggestionFeatureEnabled,
      fetchIntegrationsIfRequired,
      fetchLabelSuggestions,
    } = useAI();

    const currentAccountId = useMapGetter('getCurrentAccountId');
    const isFeatureEnabledonAccount = useMapGetter(
      'accounts/isFeatureEnabledonAccount'
    );

    const showNextBubbles = isFeatureEnabledonAccount.value(
      currentAccountId.value,
      FEATURE_FLAGS.CHATWOOT_V4
    );

    return {
      isEnterprise,
      isPopOutReplyBox,
      closePopOutReplyBox,
      showPopOutReplyBox,
      isAIIntegrationEnabled,
      isLabelSuggestionFeatureEnabled,
      fetchIntegrationsIfRequired,
      fetchLabelSuggestions,
      showNextBubbles,
    };
  },
  data() {
    return {
      isLoadingPrevious: true,
      heightBeforeLoad: null,
      conversationPanel: null,
      hasUserScrolled: false,
      isProgrammaticScroll: false,
      messageSentSinceOpened: false,
      labelSuggestions: [],
      unReadMessageIds: [],
      messagesKey: 0,
      renderingInProgress: false,
      conversationFullyLoaded: false,
    };
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUserId: 'getCurrentUserID',
      listLoadingStatus: 'getAllMessagesLoaded',
      currentAccountId: 'getCurrentAccountId',
      inboxes: 'inboxes/getInboxes',
      labelSuggestions: 'getLabelSuggestions',
    }),
    isOpen() {
      return this.currentChat?.status === wootConstants.STATUS_TYPE.OPEN;
    },
    shouldShowLabelSuggestions() {
      return (
        this.isOpen &&
        this.isEnterprise &&
        this.isAIIntegrationEnabled &&
        !this.messageSentSinceOpened
      );
    },
    inboxId() {
      return this.currentChat.inbox_id;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    typingUsersList() {
      const userList = this.$store.getters[
        'conversationTypingStatus/getUserList'
      ](this.currentChat.id);
      return userList;
    },
    isAnyoneTyping() {
      const userList = this.typingUsersList;
      return userList.length !== 0;
    },
    typingUserNames() {
      const userList = this.typingUsersList;
      if (this.isAnyoneTyping) {
        const [i18nKey, params] = getTypingUsersText(userList);
        return this.$t(i18nKey, params);
      }

      return '';
    },
    getMessages() {
      const { messages = [] } = this.currentChat || {};
      
      // EMERGENCY DEBUG: Log all messages with custom_cards content type
      const customCardMessages = messages.filter(
        message => message.content_type === 'custom_cards' || (message.content_attributes && message.content_attributes.items && message.content_attributes.items.length)
      );
      
      if (customCardMessages.length > 0) {
        console.log(
          `%c[EMERGENCY] Found ${customCardMessages.length} custom_cards messages:`, 
          'background: red; color: white; padding: 2px 5px; border-radius: 3px;',
          customCardMessages.map(msg => ({
            id: msg.id,
            content_type: msg.content_type,
            has_items: !!msg.content_attributes?.items?.length,
            items_count: msg.content_attributes?.items?.length || 0
          }))
        );
      }
      
      return messages;
    },
    readMessages() {
      const { messages = [] } = this.currentChat || {};
      if (!this.unReadMessageIds.length) {
        return messages;
      }
      
      const readMessages = messages.filter(
        message => !this.unReadMessageIds.includes(message.id)
      );
      
      // Check for custom_cards messages in readMessages
      const customCardMessages = readMessages.filter(
        message => message.content_type === 'custom_cards'
      );
      
      if (customCardMessages.length > 0) {
        /* console.log(
          `[MessagesView] Found ${customCardMessages.length} custom_cards messages in readMessages:`, 
          customCardMessages.map(msg => `ID: ${msg.id}`)
        ); */ 
      }
      
      return readMessages;
    },
    unReadMessages() {
      const { messages = [] } = this.currentChat || {};
      if (!this.unReadMessageIds.length) {
        return [];
      }
      
      const unreadMessages = messages.filter(message =>
        this.unReadMessageIds.includes(message.id)
      );
      
      // Check for custom_cards messages in unReadMessages
      const customCardMessages = unreadMessages.filter(
        message => message.content_type === 'custom_cards'
      );
      
      if (customCardMessages.length > 0) {
         /* console.log(
          `[MessagesView] Found ${customCardMessages.length} custom_cards messages in unReadMessages:`, 
          customCardMessages.map(msg => `ID: ${msg.id}`)
        ); */
      }
      
      return unreadMessages;
    },
    shouldShowSpinner() {
      return (
        (this.currentChat && this.currentChat.dataFetched === undefined) ||
        (!this.listLoadingStatus && this.isLoadingPrevious)
      );
    },
    conversationType() {
      const { additional_attributes: additionalAttributes } = this.currentChat;
      const type = additionalAttributes ? additionalAttributes.type : '';
      return type || '';
    },

    isATweet() {
      return this.conversationType === 'tweet';
    },
    isRightOrLeftIcon() {
      if (this.isContactPanelOpen) {
        return 'arrow-chevron-right';
      }
      return 'arrow-chevron-left';
    },
    getLastSeenAt() {
      const { contact_last_seen_at: contactLastSeenAt } = this.currentChat;
      return contactLastSeenAt;
    },

    // Check there is a instagram inbox exists with the same instagram_id
    hasDuplicateInstagramInbox() {
      const instagramId = this.inbox.instagram_id;
      const { additional_attributes: additionalAttributes = {} } = this.inbox;
      const instagramInbox =
        this.$store.getters['inboxes/getInstagramInboxByInstagramId'](
          instagramId
        );

      return (
        this.inbox.channel_type === INBOX_TYPES.FB &&
        additionalAttributes.type === 'instagram_direct_message' &&
        instagramInbox
      );
    },

    replyWindowBannerMessage() {
      if (this.isAWhatsAppChannel) {
        return this.$t('CONVERSATION.TWILIO_WHATSAPP_CAN_REPLY');
      }
      if (this.isAPIInbox) {
        const { additional_attributes: additionalAttributes = {} } = this.inbox;
        if (additionalAttributes) {
          const {
            agent_reply_time_window_message: agentReplyTimeWindowMessage,
            agent_reply_time_window: agentReplyTimeWindow,
          } = additionalAttributes;
          return (
            agentReplyTimeWindowMessage ||
            this.$t('CONVERSATION.API_HOURS_WINDOW', {
              hours: agentReplyTimeWindow,
            })
          );
        }
        return '';
      }
      return this.$t('CONVERSATION.CANNOT_REPLY');
    },
    replyWindowLink() {
      if (this.isAFacebookInbox || this.isAnInstagramChannel) {
        return REPLY_POLICY.FACEBOOK;
      }
      if (this.isAWhatsAppCloudChannel) {
        return REPLY_POLICY.WHATSAPP_CLOUD;
      }
      if (!this.isAPIInbox) {
        return REPLY_POLICY.TWILIO_WHATSAPP;
      }
      return '';
    },
    replyWindowLinkText() {
      if (
        this.isAWhatsAppChannel ||
        this.isAFacebookInbox ||
        this.isAnInstagramChannel
      ) {
        return this.$t('CONVERSATION.24_HOURS_WINDOW');
      }
      if (!this.isAPIInbox) {
        return this.$t('CONVERSATION.TWILIO_WHATSAPP_24_HOURS_WINDOW');
      }
      return '';
    },
    unreadMessageCount() {
      return this.currentChat.unread_count || 0;
    },
    unreadMessageLabel() {
      const count =
        this.unreadMessageCount > 9 ? '9+' : this.unreadMessageCount;
      const label =
        this.unreadMessageCount > 1
          ? 'CONVERSATION.UNREAD_MESSAGES'
          : 'CONVERSATION.UNREAD_MESSAGE';
      return `${count} ${this.$t(label)}`;
    },
    isInstagramDM() {
      return this.conversationType === 'instagram_direct_message';
    },
    inboxSupportsReplyTo() {
      const incoming = this.inboxHasFeature(INBOX_FEATURES.REPLY_TO);
      const outgoing =
        this.inboxHasFeature(INBOX_FEATURES.REPLY_TO_OUTGOING) &&
        !this.is360DialogWhatsAppChannel;

      return { incoming, outgoing };
    },
  },

  watch: {
    currentChat: {
      immediate: true,
      deep: true,
      handler(newChat, oldChat) {
        if (newChat.id !== (oldChat?.id || null)) {
          console.log(`[MessagesView] Conversation changed to ID ${newChat.id}`);
          
          // Reset flags
          this.conversationFullyLoaded = false;
          this.messageSentSinceOpened = false;
          
          // Fetch data
          this.fetchAllAttachmentsFromCurrentChat();
          this.fetchSuggestions();
          
          // Update unReadMessageIds when the currentChat changes
          this.updateUnreadMessageIds();
          
          // Schedule a comprehensive message scan after a short delay to ensure all messages are loaded
          setTimeout(() => {
            this.performComprehensiveMessageScan();
          }, 500);
        } else if (newChat.messages?.length !== oldChat?.messages?.length) {
          console.log(`[MessagesView] Messages array changed from ${oldChat?.messages?.length || 0} to ${newChat.messages?.length || 0} messages`);
          this.updateUnreadMessageIds();
          this.$nextTick(() => {
            this.inspectCustomCardMessages();
            this.scrollToBottom();
          });
        }
      }
    },
    'currentChat.messages': {
      deep: true,
      immediate: true,
      handler(newMessages, oldMessages) {
        if (!newMessages || !oldMessages) return;
        
        // First check for message array length changes
        if (newMessages.length !== oldMessages.length) {
          console.log(`[MessagesView] Messages array changed: ${oldMessages.length} → ${newMessages.length}`);
          
          // Get only the new messages (that weren't in the old array)
          const newMsgs = newMessages.filter(
            msg => !oldMessages.some(oldMsg => oldMsg.id === msg.id)
          );
          
          // Check for custom_cards specifically
          const newCustomCards = newMsgs.filter(
            msg => msg.content_type === 'custom_cards' || 
                  (msg.content_attributes?.items && msg.content_attributes.items.length)
          );
          
          if (newCustomCards.length > 0) {
            console.log(`[MessagesView] 🔥 EMERGENCY: Detected ${newCustomCards.length} new custom_cards messages:`);
            console.table(newCustomCards.map(m => ({ 
              id: m.id, 
              type: m.content_type, 
              items: m.content_attributes?.items?.length || 0 
            })));
            
            // Manually force content_type if needed
            newCustomCards.forEach(msg => {
              if (msg.content_attributes?.items?.length && msg.content_type !== 'custom_cards') {
                console.log(`[MessagesView] 🛠️ Fixing content_type for message ${msg.id} to 'custom_cards'`);
                msg.content_type = 'custom_cards';
              }
            });
            
            // Use safe approach to update
            this.safeForceRerender();
          }
        }
      }
    }
  },

  created() {
    emitter.on(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
    // when a new message comes in, we refetch the label suggestions
    emitter.on(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS, this.fetchSuggestions);
    // when a message is sent we set the flag to true this hides the label suggestions,
    // until the chat is changed and the flag is reset in the watch for currentChat
    emitter.on(BUS_EVENTS.MESSAGE_SENT, () => {
      this.messageSentSinceOpened = true;
    });
  },

  mounted() {
    this.$nextTick(() => {
      this.addScrollListener();
    });
    this.fetchAllAttachmentsFromCurrentChat();
    this.fetchSuggestions();
    
    // Call our new debug method on mounted
    this.inspectCustomCardMessages();
  },

  unmounted() {
    this.removeBusListeners();
    // Only try to remove event listener if conversationPanel exists
    if (this.conversationPanel) {
      this.removeScrollListener();
    }
  },

  methods: {
    async fetchSuggestions() {
      // start empty, this ensures that the label suggestions are not shown
      this.labelSuggestions = [];

      if (this.isLabelSuggestionDismissed()) {
        return;
      }

      if (!this.isEnterprise) {
        return;
      }

      // method available in mixin, need to ensure that integrations are present
      await this.fetchIntegrationsIfRequired();

      if (!this.isLabelSuggestionFeatureEnabled) {
        return;
      }

      this.labelSuggestions = await this.fetchLabelSuggestions({
        conversationId: this.currentChat.id,
      });

      // once the labels are fetched, we need to scroll to bottom
      // but we need to wait for the DOM to be updated
      // so we use the nextTick method
      this.$nextTick(() => {
        // this param is added to route, telling the UI to navigate to the message
        // it is triggered by the SCROLL_TO_MESSAGE method
        // see setActiveChat on ConversationView.vue for more info
        const { messageId } = this.$route.query;

        // only trigger the scroll to bottom if the user has not scrolled
        // and there's no active messageId that is selected in view
        if (!messageId && !this.hasUserScrolled) {
          this.scrollToBottom();
        }
      });
    },
    
    // Add diagnostic function here
    /*
    runContentTypeAudit() {
      console.log('=== STARTING CONTENT TYPE AUDIT ===');
      if (!this.currentChat || !this.currentChat.messages) {
        console.log('No messages to audit');
        return;
      }

      const messages = this.currentChat.messages;
      console.log(`Auditing ${messages.length} messages in conversation ${this.currentChat.id}`);
      
      // Find custom_cards messages
      const customCardMessages = messages.filter(msg => 
        msg.content_type === 'custom_cards' || 
        msg.content_attributes?.items?.length > 0
      );
      
      console.log(`Found ${customCardMessages.length} custom_cards messages`);
      
      // Detailed logging of all custom_cards messages
      customCardMessages.forEach(msg => {
        console.log(`Custom card message ID ${msg.id}:`);
        console.log(`  content_type: ${msg.content_type}`);
        console.log(`  has items: ${!!msg.content_attributes?.items}`);
        console.log(`  items length: ${msg.content_attributes?.items?.length || 0}`);
        
        // Force content_type to custom_cards if it has items
        if (msg.content_attributes?.items && msg.content_type !== 'custom_cards') {
          console.log(`  ⚠️ Fixing content_type to 'custom_cards'`);
          msg.content_type = 'custom_cards';
        }
        
        // Try manually forcing DOM update
        const msgElement = document.getElementById(`message${msg.id}`);
        if (msgElement) {
          console.log(`  ✅ Found message element in DOM, adding debug marker`);
          msgElement.style.border = '5px solid red';
          msgElement.style.position = 'relative';
          msgElement.style.zIndex = '9999';
          
          // Add a debug overlay
          const debugDiv = document.createElement('div');
          debugDiv.style.backgroundColor = 'yellow';
          debugDiv.style.color = 'black';
          debugDiv.style.padding = '10px';
          debugDiv.style.margin = '10px 0';
          debugDiv.style.border = '2px dashed purple';
          debugDiv.innerHTML = `
            <h3 style="color: black;">Audit Marker: Custom Card ${msg.id}</h3>
            <p>Content type: ${msg.content_type}</p>
            <p>Items: ${msg.content_attributes?.items?.length || 0}</p>
          `;
          msgElement.appendChild(debugDiv);
        } else {
          console.log(`  ❌ Couldn't find message element in DOM`);
        }
      });
      
      console.log('=== AUDIT COMPLETE ===');
      this.$forceUpdate(); // Force component to re-render
    },
    */
    
    isLabelSuggestionDismissed() {
      return LocalStorage.getFlag(
        LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS,
        this.currentAccountId,
        this.currentChat.id
      );
    },
    fetchAllAttachmentsFromCurrentChat() {
      this.$store.dispatch('fetchAllAttachments', this.currentChat.id);
    },
    removeBusListeners() {
      emitter.off(BUS_EVENTS.SCROLL_TO_MESSAGE, this.onScrollToMessage);
    },
    onScrollToMessage({ messageId = '' } = {}) {
      this.$nextTick(() => {
        const messageElement = document.getElementById('message' + messageId);
        if (messageElement) {
          this.isProgrammaticScroll = true;
          messageElement.scrollIntoView({ behavior: 'smooth' });
          this.fetchPreviousMessages();
        } else {
          this.scrollToBottom();
        }
      });
      this.makeMessagesRead();
    },
    addScrollListener() {
      // Ensure this.$el exists and is a DOM element
      if (!this.$el || typeof this.$el.querySelector !== 'function') {
        console.warn('[MessagesView] $el not ready for querySelector');
        return;
      }
      
      this.conversationPanel = this.$el.querySelector('.conversation-panel');
      if (!this.conversationPanel) {
        console.warn('[MessagesView] Conversation panel not found');
        return;
      }
      
      this.setScrollParams();
      this.conversationPanel.addEventListener('scroll', this.handleScroll);
      this.$nextTick(() => this.scrollToBottom());
      this.isLoadingPrevious = false;
    },
    removeScrollListener() {
      if (this.conversationPanel) {
        this.conversationPanel.removeEventListener('scroll', this.handleScroll);
      }
    },
    scrollToBottom() {
      this.isProgrammaticScroll = true;
      let relevantMessages = [];

      // label suggestions are not part of the messages list
      // so we need to handle them separately
      let labelSuggestions =
        this.conversationPanel.querySelector('.label-suggestion');

      // if there are unread messages, scroll to the first unread message
      if (this.unreadMessageCount > 0) {
        // capturing only the unread messages
        relevantMessages =
          this.conversationPanel.querySelectorAll('.message--unread');
      } else if (labelSuggestions) {
        // when scrolling to the bottom, the label suggestions is below the last message
        // so we scroll there if there are no unread messages
        // Unread messages always take the highest priority
        relevantMessages = [labelSuggestions];
      } else {
        // if there are no unread messages or label suggestion, scroll to the last message
        // capturing last message from the messages list
        relevantMessages = Array.from(
          this.conversationPanel.querySelectorAll('.message--read')
        ).slice(-1);
      }

      this.conversationPanel.scrollTop = calculateScrollTop(
        this.conversationPanel.scrollHeight,
        this.$el.scrollHeight,
        relevantMessages
      );
    },
    onToggleContactPanel() {
      this.$emit('contactPanelToggle');
    },
    setScrollParams() {
      this.heightBeforeLoad = this.conversationPanel.scrollHeight;
      this.scrollTopBeforeLoad = this.conversationPanel.scrollTop;
    },

    async fetchPreviousMessages(scrollTop = 0) {
      this.setScrollParams();
      const shouldLoadMoreMessages =
        this.currentChat.dataFetched === true &&
        !this.listLoadingStatus &&
        !this.isLoadingPrevious;

      if (
        scrollTop < 100 &&
        !this.isLoadingPrevious &&
        shouldLoadMoreMessages
      ) {
        this.isLoadingPrevious = true;
        try {
          const oldMessageCount = this.currentChat.messages.length;
          
          await this.$store.dispatch('fetchPreviousMessages', {
            conversationId: this.currentChat.id,
            before: this.currentChat.messages[0].id,
          });
          
          const newMessageCount = this.currentChat.messages.length;
          const heightDifference =
            this.conversationPanel.scrollHeight - this.heightBeforeLoad;
          this.conversationPanel.scrollTop =
            this.scrollTopBeforeLoad + heightDifference;
          this.setScrollParams();
          
          // Check if we loaded new messages and scan them for custom cards
          if (newMessageCount > oldMessageCount) {
            console.log(`[MessagesView] Loaded ${newMessageCount - oldMessageCount} older messages`);
            this.scanNewlyLoadedMessages(oldMessageCount);
          }
        } catch (error) {
          console.error('[MessagesView] Error loading previous messages:', error);
        } finally {
          this.isLoadingPrevious = false;
        }
      }
    },

    scanNewlyLoadedMessages(oldMessageCount) {
      if (!this.currentChat || !this.currentChat.messages) return;
      
      // Get only the newly loaded messages (which would be at the beginning of the array)
      const newMessages = this.currentChat.messages.slice(0, this.currentChat.messages.length - oldMessageCount);
      console.log(`[MessagesView] Scanning ${newMessages.length} newly loaded messages for custom cards`);
      
      // Find custom card messages among the new ones
      const newCustomCardMessages = newMessages.filter(msg => 
        msg.content_type === 'custom_cards' || 
        (msg.content_attributes && msg.content_attributes.items && msg.content_attributes.items.length)
      );
      
      if (newCustomCardMessages.length > 0) {
        console.log(`[MessagesView] Found ${newCustomCardMessages.length} custom card messages in newly loaded history`);
        
        // Fix any messages with incorrect content_type
        newCustomCardMessages.forEach(msg => {
          if (msg.content_attributes?.items?.length && msg.content_type !== 'custom_cards') {
            console.log(`[MessagesView] Fixing content_type for older message ${msg.id}`);
            msg.content_type = 'custom_cards';
          }
        });
        
        // Force rerender to ensure the new custom cards are displayed
        this.safeForceRerender();
        
        // Verify visibility after a short delay
        setTimeout(() => {
          // Check if the DOM elements for these messages exist
          const missingMessages = newCustomCardMessages.filter(msg => 
            !document.getElementById(`message${msg.id}`)
          );
          
          if (missingMessages.length > 0) {
            console.warn(`[MessagesView] ⚠️ Some older custom card messages are not visible in DOM:`, 
              missingMessages.map(m => m.id)
            );
            this.safeForceRerender();
          }
        }, 1000);
      }
    },

    handleScroll(e) {
      if (this.isProgrammaticScroll) {
        // Reset the flag
        this.isProgrammaticScroll = false;
        this.hasUserScrolled = false;
      } else {
        this.hasUserScrolled = true;
      }
      emitter.emit(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL);
      this.fetchPreviousMessages(e.target.scrollTop);
    },

    makeMessagesRead() {
      this.$store.dispatch('markMessagesRead', { id: this.currentChat.id });
    },
    getInReplyToMessage(parentMessage) {
      if (!parentMessage) return {};
      const inReplyToMessageId = parentMessage.content_attributes?.in_reply_to;
      if (!inReplyToMessageId) return {};

      return this.currentChat?.messages.find(message => {
        if (message.id === inReplyToMessageId) {
          return true;
        }
        return false;
      });
    },
    updateUnreadMessageIds() {
      if (!this.currentChat || !this.currentChat.messages) {
        console.warn('[MessagesView] updateUnreadMessageIds called with no messages');
        this.unReadMessageIds = [];
        return;
      }
      
      const messages = this.currentChat.messages || [];
      console.log(`[MessagesView] Updating unread message IDs. Total messages: ${messages.length}`);
      
      // Only update unread IDs if there are messages
      if (messages.length > 0) {
        const unreadMessages = getUnreadMessages(
          messages,
          this.currentChat.agent_last_seen_at
        );
        
        this.unReadMessageIds = unreadMessages.map(message => message.id);
        
        console.log(`[MessagesView] Set ${this.unReadMessageIds.length} unread message IDs:`, 
          this.unReadMessageIds);
          
        // Immediately log the impact on readMessages and unReadMessages computed properties  
        this.$nextTick(() => {
          console.log(`[MessagesView] After update: readMessages=${this.readMessages.length}, unReadMessages=${this.unReadMessages.length}`);
          
          // Detect any custom_cards messages in unReadMessages
          const customCards = this.unReadMessages.filter(msg => 
            msg.content_type === 'custom_cards' || 
            (msg.content_attributes?.items && msg.content_attributes.items.length > 0)
          );
          
          if (customCards.length > 0) {
            console.log(`[MessagesView] Found ${customCards.length} custom_cards in unReadMessages:`,
              customCards.map(m => ({id: m.id, type: m.content_type})));
          }
          
          // Force rerender to ensure message components are updated
          this.$forceUpdate();
        });
      } else {
        this.unReadMessageIds = [];
        console.warn('[MessagesView] No messages found in currentChat.messages');
      }
    },
    // Add emergency debugging method
    inspectCustomCardMessages() {
      console.log('%c[EMERGENCY DEBUG] Inspecting messages for custom cards', 'background: #ff5722; color: white; padding: 2px 5px;');
      
      if (!this.currentChat || !this.currentChat.messages) {
        console.log('[EMERGENCY DEBUG] No messages found in currentChat');
        return;
      }
      
      const allMessages = this.currentChat.messages;
      console.log(`[EMERGENCY DEBUG] Total messages in conversation: ${allMessages.length}`);
      
      // Find all messages with custom cards
      const customCardMessages = allMessages.filter(msg => 
        msg.content_type === 'custom_cards' || 
        (msg.content_attributes && msg.content_attributes.items && msg.content_attributes.items.length)
      );
      
      if (customCardMessages.length === 0) {
        console.log('[EMERGENCY DEBUG] No custom card messages found');
        return;
      }
      
      console.log(`%c[EMERGENCY DEBUG] Found ${customCardMessages.length} custom card messages:`, 'background: #4caf50; color: white; padding: 2px 5px;');
      
      // Log details about each custom card message
      customCardMessages.forEach(msg => {
        console.log(`%c[EMERGENCY DEBUG] Message ID: ${msg.id}`, 'font-weight: bold; color: #e91e63;');
        console.log('Content type:', msg.content_type);
        console.log('Has items:', !!msg.content_attributes?.items);
        console.log('Items count:', msg.content_attributes?.items?.length || 0);
        
        // Fix content_type if needed
        if (msg.content_attributes?.items?.length && msg.content_type !== 'custom_cards') {
          console.warn(`%c[EMERGENCY FIX] Message ${msg.id} has items but wrong content_type: ${msg.content_type}`, 
              'background: #ff9800; color: black; padding: 2px 5px;');
          
          // Force it to be custom_cards if it has items
          msg.content_type = 'custom_cards';
        }
      });
      
      // Force rerender after inspecting/fixing - use the safe version
      this.safeForceRerender();
    },
    logRenderedMessage(message, type) {
      console.log(`[MessagesView] Rendering message ID ${message.id} (Type: ${message.content_type}) in ${type} loop`);
      return null; // :set expects a value, return null
    },
    forceMessageListRerender() {
      if (this.renderingInProgress) {
        console.log('[MessagesView] Rendering already in progress, skipping duplicate request');
        return;
      }
      
      console.log('[MessagesView] Forcing message list rerender');
      this.renderingInProgress = true;
      this.messagesKey++; 
      
      // Use nextTick instead of direct forceUpdate
      nextTick(() => {
        try {
          // Try to safely interact with the DOM
          if (document && document.querySelectorAll) {
            const messageElements = document.querySelectorAll('[id^="message"]');
            console.log(`[MessagesView] After rerender tick, found ${messageElements.length} message elements in DOM`);
          }
        } catch (err) {
          console.error('[MessagesView] Error during DOM check:', err);
        }
        
        this.renderingInProgress = false;
      });
    },
    safeForceRerender() {
      if (this.renderingInProgress) {
        console.log('[MessagesView] Rendering already in progress, will try again later');
        setTimeout(() => this.safeForceRerender(), 200); // Try again later
        return;
      }
      
      console.log('[MessagesView] 🔄 Safely forcing rerender with debounce');
      this.renderingInProgress = true;
      
      // Increment the key to force Vue's virtual DOM to recreate the components
      this.messagesKey++;
      
      // Immediately update unread message IDs
      this.updateUnreadMessageIds();
      
      // Use a proper Vue nextTick + setTimeout for maximum safety
      nextTick(() => {
        // First wait for Vue's internal update cycle
        setTimeout(() => {
          try {
            // Track how many message elements are in the DOM
            const messageElementCount = document.querySelectorAll('[id^="message"]').length;
            console.log(`[MessagesView] ✓ Safe rerender complete, found ${messageElementCount} message elements`);
            
            // Force the component to update if needed
            this.$forceUpdate();
            
            // Ensure scroll to latest messages
            if (!this.hasUserScrolled) {
              this.scrollToBottom();
            }
          } catch (err) {
            console.error('[MessagesView] Error during safe rerender:', err);
          } finally {
            this.renderingInProgress = false;
          }
        }, 100); // Small delay to ensure things are settled
      });
    },
    // Modify the emergencyRenderCustomCards method
    emergencyRenderCustomCards() {
      console.log('[MessagesView] 🚨 EMERGENCY: Direct custom card rendering triggered');
      
      // Find all custom card messages
      if (!this.currentChat || !this.currentChat.messages) {
        console.log('[MessagesView] No messages found for emergency rendering');
        return;
      }
      
      const customCardMessages = this.currentChat.messages.filter(msg => 
        msg.content_type === 'custom_cards' || 
        (msg.content_attributes?.items && msg.content_attributes.items.length)
      );
      
      if (customCardMessages.length === 0) {
        console.log('[MessagesView] No custom card messages found for emergency rendering');
        return;
      }
      
      console.log(`[MessagesView] Found ${customCardMessages.length} custom card messages for emergency rendering`);
      
      // Create emergency container if it doesn't exist
      let emergencyContainer = document.getElementById('emergency-custom-cards');
      if (!emergencyContainer) {
        emergencyContainer = document.createElement('div');
        emergencyContainer.id = 'emergency-custom-cards';
        emergencyContainer.style.cssText = 'position: fixed; bottom: 20px; right: 20px; width: 350px; max-height: 500px; overflow-y: auto; background: white; padding: 10px; border: 3px solid #E91E63; z-index: 9999; box-shadow: 0 0 20px rgba(0,0,0,0.3); border-radius: 8px;';
        
        const header = document.createElement('h2');
        header.textContent = 'Emergency Custom Cards';
        header.style.cssText = 'margin: 0 0 10px 0; color: #E91E63; border-bottom: 1px solid #ccc; padding-bottom: 8px;';
        emergencyContainer.appendChild(header);
        
        document.body.appendChild(emergencyContainer);
      } else {
        // Clear existing cards
        while (emergencyContainer.children.length > 1) { // Keep the header
          emergencyContainer.removeChild(emergencyContainer.lastChild);
        }
      }
      
      // Store reference to component instance for event handlers
      const self = this;
      
      // Add each custom card message
      customCardMessages.forEach(msg => {
        const msgId = msg.id;
        const items = msg.content_attributes?.items || [];
        
        // Create card container
        const cardContainer = document.createElement('div');
        cardContainer.style.cssText = 'margin-bottom: 15px; padding: 8px; border: 1px solid #ccc; border-radius: 5px; position: relative;';
        
        // Add message info
        const infoContainer = document.createElement('div');
        infoContainer.style.cssText = 'display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;';
        
        const info = document.createElement('div');
        info.textContent = `ID: ${msgId} | Items: ${items.length}`;
        info.style.cssText = 'font-size: 12px; color: #666;';
        infoContainer.appendChild(info);
        
        // Add analyze button
        const analyzeBtn = document.createElement('button');
        analyzeBtn.textContent = 'Analyze';
        analyzeBtn.style.cssText = 'background: #2196F3; color: white; border: none; border-radius: 4px; padding: 3px 8px; font-size: 11px; cursor: pointer;';
        analyzeBtn.onclick = function() {
          self.analyzeCustomCardItems(msgId);
        };
        infoContainer.appendChild(analyzeBtn);
        
        cardContainer.appendChild(infoContainer);
        
        // Show content type warning if needed
        if (msg.content_type !== 'custom_cards') {
          const warning = document.createElement('div');
          warning.textContent = `⚠️ Wrong content_type: ${msg.content_type}`;
          warning.style.cssText = 'font-size: 11px; color: white; background: #FF5722; padding: 3px 5px; border-radius: 3px; margin-bottom: 8px;';
          cardContainer.appendChild(warning);
        }
        
        // If no items, show error
        if (!items.length) {
          const error = document.createElement('div');
          error.textContent = 'No items found for this message';
          error.style.cssText = 'font-size: 12px; color: #D32F2F; padding: 8px; background: #FFEBEE; border-radius: 4px;';
          cardContainer.appendChild(error);
          emergencyContainer.appendChild(cardContainer);
          return; // Skip further processing
        }
        
        // Check if items is actually an array
        if (!Array.isArray(items)) {
          const error = document.createElement('div');
          error.textContent = `CRITICAL: items is not an array (${typeof items})`;
          error.style.cssText = 'font-size: 12px; color: #D32F2F; padding: 8px; background: #FFEBEE; border-radius: 4px;';
          cardContainer.appendChild(error);
          
          // Add a dump button to see the raw value
          const dumpBtn = document.createElement('button');
          dumpBtn.textContent = 'Dump Raw Value';
          dumpBtn.style.cssText = 'background: #E91E63; color: white; border: none; border-radius: 4px; padding: 3px 8px; font-size: 11px; cursor: pointer; margin-top: 5px;';
          dumpBtn.onclick = function() {
            console.log('Raw items value:', items);
            alert('Raw value dumped to console. Check Developer Tools.');
          };
          cardContainer.appendChild(dumpBtn);
          
          emergencyContainer.appendChild(cardContainer);
          return; // Skip further processing
        }
        
        // Add each item
        items.forEach((item, index) => {
          if (typeof item !== 'object' || item === null) {
            const error = document.createElement('div');
            error.textContent = `Item ${index} is not an object: ${typeof item}`;
            error.style.cssText = 'font-size: 12px; color: #D32F2F; padding: 8px; background: #FFEBEE; border-radius: 4px; margin-bottom: 8px;';
            cardContainer.appendChild(error);
            return;
          }
          
          const itemEl = document.createElement('div');
          itemEl.style.cssText = 'margin-bottom: 8px; padding: 8px; background: #f5f5f5; border-radius: 4px;';
          
          if (item.title) {
            const title = document.createElement('h3');
            title.textContent = item.title;
            title.style.cssText = 'margin: 0 0 5px 0; font-size: 14px; color: #333;';
            itemEl.appendChild(title);
          }
          
          if (item.image_url) {
            const img = document.createElement('img');
            img.src = item.image_url;
            img.alt = item.title || 'Image';
            img.style.cssText = 'width: 100%; height: auto; margin-bottom: 5px; border-radius: 3px;';
            img.onerror = function() {
              this.style.display = 'none';
              const error = document.createElement('div');
              error.textContent = '❌ Image failed to load';
              error.style.cssText = 'font-size: 11px; color: #D32F2F; padding: 3px; background: #FFEBEE; border-radius: 3px; margin-bottom: 5px;';
              itemEl.insertBefore(error, this.nextSibling);
            };
            itemEl.appendChild(img);
          }
          
          if (item.description) {
            const desc = document.createElement('p');
            desc.textContent = item.description;
            desc.style.cssText = 'margin: 0 0 5px 0; font-size: 12px; color: #666;';
            itemEl.appendChild(desc);
          }
          
          if (item.actions && Array.isArray(item.actions) && item.actions.length > 0) {
            const actions = document.createElement('div');
            actions.style.cssText = 'display: flex; flex-wrap: wrap; gap: 5px; margin-top: 5px;';
            
            item.actions.forEach(action => {
              const actionBtn = document.createElement('button');
              actionBtn.textContent = action.text || 'Action';
              actionBtn.style.cssText = action.type === 'link' ? 
                'padding: 3px 8px; font-size: 11px; background: #E3F2FD; color: #0D47A1; border: none; border-radius: 3px; cursor: pointer;' : 
                'padding: 3px 8px; font-size: 11px; background: #E8F5E9; color: #1B5E20; border: none; border-radius: 3px; cursor: pointer;';
              
              if (action.type === 'link' && action.uri) {
                actionBtn.onclick = function() {
                  window.open(action.uri, '_blank');
                };
              }
              
              actions.appendChild(actionBtn);
            });
            
            itemEl.appendChild(actions);
          }
          
          cardContainer.appendChild(itemEl);
        });
        
        emergencyContainer.appendChild(cardContainer);
      });
      
      console.log('[MessagesView] Emergency custom cards rendering complete');
    },
    analyzeCustomCardItems(messageId) {
      console.log(`[MessagesView] 🔍 Analyzing custom card items for message ${messageId}`);
      
      if (!this.currentChat || !this.currentChat.messages) {
        console.log('No messages found');
        return;
      }
      
      // Find the message by ID
      const message = this.currentChat.messages.find(m => m.id === messageId);
      if (!message) {
        console.log(`Message with ID ${messageId} not found`);
        return;
      }
      
      console.log('Message data:', message);
      
      // Check content_type
      console.log(`Content type: ${message.content_type}`);
      if (message.content_type !== 'custom_cards') {
        console.log(`⚠️ WARNING: Content type is not 'custom_cards'`);
      }
      
      // Check for items in content_attributes
      const contentAttributes = message.content_attributes || {};
      console.log('Content attributes:', contentAttributes);
      
      // Check direct properties
      const hasDirectItems = 'items' in contentAttributes;
      console.log(`Has direct 'items' property: ${hasDirectItems}`);
      
      // Check if items is an array
      const items = contentAttributes.items;
      const isItemsArray = Array.isArray(items);
      console.log(`Items is an array: ${isItemsArray}`);
      
      if (!isItemsArray) {
        console.log(`⚠️ CRITICAL: Items is not an array or is undefined`);
        console.log(`Items type: ${typeof items}`);
        console.log(`Items value:`, items);
        
        if (typeof items === 'string') {
          console.log(`Attempting to parse items string as JSON`);
          try {
            const parsedItems = JSON.parse(items);
            console.log(`Parsed items:`, parsedItems);
            console.log(`Is parsed items an array: ${Array.isArray(parsedItems)}`);
          } catch (err) {
            console.log(`Failed to parse items string as JSON:`, err);
          }
        }
        
        return;
      }
      
      // Check items length
      console.log(`Items length: ${items.length}`);
      
      if (items.length === 0) {
        console.log(`⚠️ WARNING: Items array is empty`);
        return;
      }
      
      // Analyze each item
      items.forEach((item, index) => {
        console.log(`\nItem ${index + 1}:`);
        console.log(`Type: ${typeof item}`);
        
        if (typeof item !== 'object' || item === null) {
          console.log(`⚠️ CRITICAL: Item is not an object`);
          console.log(`Item value:`, item);
          return;
        }
        
        // Check required properties
        const requiredProps = ['title', 'description', 'actions'];
        const missingProps = requiredProps.filter(prop => !(prop in item));
        
        if (missingProps.length > 0) {
          console.log(`⚠️ WARNING: Missing required properties: ${missingProps.join(', ')}`);
        }
        
        // Log all properties
        Object.keys(item).forEach(key => {
          console.log(`${key}: ${typeof item[key]} = ${JSON.stringify(item[key])}`);
        });
        
        // Check actions if present
        if (Array.isArray(item.actions)) {
          console.log(`Actions length: ${item.actions.length}`);
          
          item.actions.forEach((action, actionIndex) => {
            console.log(`  Action ${actionIndex + 1}:`);
            console.log(`  Type: ${action.type}`);
            console.log(`  Text: ${action.text}`);
            
            if (action.type === 'link' && !action.uri) {
              console.log(`  ⚠️ WARNING: Link action missing uri`);
            } else if (action.type === 'postback' && !action.payload) {
              console.log(`  ⚠️ WARNING: Postback action missing payload`);
            }
          });
        }
      });
      
      console.log('[MessagesView] Analysis complete');
    },
    performComprehensiveMessageScan() {
      console.log('[MessagesView] 🔍 Performing comprehensive message scan');
      
      if (!this.currentChat || !this.currentChat.messages) {
        console.log('[MessagesView] No messages to scan');
        return;
      }
      
      const allMessages = this.currentChat.messages;
      console.log(`[MessagesView] Scanning ${allMessages.length} total messages`);
      
      // Find all custom card messages
      const customCardMessages = allMessages.filter(msg => 
        msg.content_type === 'custom_cards' || 
        (msg.content_attributes && msg.content_attributes.items && msg.content_attributes.items.length)
      );
      
      console.log(`[MessagesView] Found ${customCardMessages.length} custom card messages during comprehensive scan`);
      
      // Fix any messages with incorrect content_type
      let fixedCount = 0;
      customCardMessages.forEach(msg => {
        if (msg.content_attributes?.items?.length && msg.content_type !== 'custom_cards') {
          console.log(`[MessagesView] Fixing content_type for message ${msg.id}`);
          msg.content_type = 'custom_cards';
          fixedCount++;
        }
      });
      
      if (fixedCount > 0) {
        console.log(`[MessagesView] Fixed content_type for ${fixedCount} messages`);
      }
      
      // Force rerender
      if (customCardMessages.length > 0) {
        console.log('[MessagesView] Forcing rerender after comprehensive scan');
        this.safeForceRerender();
        
        // After a delay, verify all messages are visible
        setTimeout(() => {
          this.verifyCustomCardVisibility(customCardMessages);
        }, 1000);
      }
      
      this.conversationFullyLoaded = true;
      console.log('[MessagesView] Comprehensive scan complete');
    },
    verifyCustomCardVisibility(customCardMessages) {
      console.log('[MessagesView] 🔍 Verifying custom card visibility');
      
      // Check how many custom card elements are actually in the DOM
      const customCardElements = document.querySelectorAll('.custom-card-container');
      console.log(`[MessagesView] Found ${customCardElements.length} custom card elements in DOM`);
      
      if (customCardElements.length < customCardMessages.length) {
        console.warn(`[MessagesView] ⚠️ Missing custom cards! Expected ${customCardMessages.length} but found ${customCardElements.length}`);
        
        // Create a map of visible message IDs
        const visibleMessageIds = new Set();
        document.querySelectorAll('[id^="message"]').forEach(el => {
          const id = el.id.replace('message', '');
          visibleMessageIds.add(id);
        });
        
        // Find which messages are missing
        const missingMessages = customCardMessages.filter(msg => 
          !visibleMessageIds.has(String(msg.id))
        );
        
        console.log('[MessagesView] Missing custom card messages:', missingMessages.map(m => m.id));
        
        // Emergency fix - try one more rerender
        this.safeForceRerender();
        
        // If after retrying we still have missing cards, trigger emergency rendering
        setTimeout(() => {
          const updatedCardElements = document.querySelectorAll('.custom-card-container');
          if (updatedCardElements.length < customCardMessages.length) {
            console.warn('[MessagesView] 🚨 Still missing custom cards after rerender, activating emergency rendering');
            this.emergencyRenderCustomCards();
          }
        }, 1000);
      } else {
        console.log('[MessagesView] ✅ All custom cards are visible in DOM');
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col justify-between flex-grow h-full min-w-0 m-0">
    <!-- DIAGNOSTIC TOOLBAR - For debugging only -->
    <div class="diagnostic-toolbar" style="background-color: #ffd700; padding: 10px; margin: 5px; border-radius: 4px;">
      <h4 style="color: black; margin: 0 0 8px 0;">Debug Tools</h4>
      <button 
        style="background-color: #e91e63; color: white; padding: 5px 10px; border: none; border-radius: 4px; cursor: pointer; margin-right: 5px;" 
        @click="runContentTypeAudit"
      >
        Audit Custom Cards
      </button>
      <button 
        style="background-color: #4caf50; color: white; padding: 5px 10px; border: none; border-radius: 4px; cursor: pointer; margin-right: 5px;" 
        @click="safeForceRerender"
      >
        Force Rerender
      </button>
      <button 
        style="background-color: #ff5722; color: white; padding: 5px 10px; border: none; border-radius: 4px; cursor: pointer; margin-right: 5px;" 
        @click="emergencyRenderCustomCards"
      >
        EMERGENCY VIEW
      </button>
      <button 
        style="background-color: #2196F3; color: white; padding: 5px 10px; border: none; border-radius: 4px; cursor: pointer; margin-right: 5px;" 
        @click="performComprehensiveMessageScan"
      >
        EMERGENCY SCAN
      </button>
      <span style="color: black; font-size: 12px;">Found {{currentChat?.messages?.filter(m => m.content_type === 'custom_cards' || (m.content_attributes?.items && m.content_attributes.items.length)).length || 0}} custom_cards</span>
    </div>

    <Banner
      v-if="!currentChat.can_reply"
      color-scheme="alert"
      class="mx-2 mt-2 overflow-hidden rounded-lg"
      :banner-message="replyWindowBannerMessage"
      :href-link="replyWindowLink"
      :href-link-text="replyWindowLinkText"
    />
    <Banner
      v-else-if="hasDuplicateInstagramInbox"
      color-scheme="alert"
      class="mx-2 mt-2 overflow-hidden rounded-lg"
      :banner-message="$t('CONVERSATION.OLD_INSTAGRAM_INBOX_REPLY_BANNER')"
    />
    <div class="flex justify-end">
      <NextButton
        faded
        xs
        slate
        class="!rounded-r-none rtl:rotate-180 !rounded-2xl !fixed z-10"
        :icon="
          isContactPanelOpen ? 'i-ph-caret-right-fill' : 'i-ph-caret-left-fill'
        "
        :class="isInboxView ? 'top-52 md:top-40' : 'top-32'"
        @click="onToggleContactPanel"
      />
    </div>
    <NextMessageList
      v-if="showNextBubbles"
      class="conversation-panel"
      :current-user-id="currentUserId"
      :first-unread-id="unReadMessages[0]?.id"
      :is-an-email-channel="isAnEmailChannel"
      :inbox-supports-reply-to="inboxSupportsReplyTo"
      :messages="getMessages"
    >
      <template #beforeAll>
        <transition name="slide-up">
          <!-- eslint-disable-next-line vue/require-toggle-inside-transition -->
          <li class="min-h-[4rem]">
            <span v-if="shouldShowSpinner" class="spinner message" />
          </li>
        </transition>
      </template>
      <template #unreadBadge>
        <li v-show="unreadMessageCount != 0" class="unread--toast">
          <span>
            {{ unreadMessageLabel }}
          </span>
        </li>
      </template>
      <template #after>
        <ConversationLabelSuggestion
          v-if="shouldShowLabelSuggestions"
          :suggested-labels="labelSuggestions"
          :chat-labels="currentChat.labels"
          :conversation-id="currentChat.id"
        />
      </template>
    </NextMessageList>
    <ul v-else class="conversation-panel">
      <transition name="slide-up">
        <!-- eslint-disable-next-line vue/require-toggle-inside-transition -->
        <li class="min-h-[4rem]">
          <span v-if="shouldShowSpinner" class="spinner message" />
        </li>
      </transition>
      
      <!-- Emergency rendering of any missed custom cards -->
      <template v-if="currentChat && currentChat.messages">
        <Message
          v-for="message in currentChat.messages.filter(m => 
            (m.content_type === 'custom_cards' || 
             (m.content_attributes && m.content_attributes.items && m.content_attributes.items.length)) &&
            !readMessages.some(rm => rm.id === m.id) && 
            !unReadMessages.some(um => um.id === m.id)
          )"
          :key="`emergency-${message.id}-${messagesKey}`"
          class="message--emergency ph-no-capture"
          data-clarity-mask="True"
          :data="message"
          :is-a-tweet="isATweet"
          :is-a-whatsapp-channel="isAWhatsAppChannel"
          :is-web-widget-inbox="isAWebWidgetInbox"
          :is-a-facebook-inbox="isAFacebookInbox"
          :is-an-email-inbox="isAnEmailChannel"
          :is-instagram="isInstagramDM"
          :inbox-supports-reply-to="inboxSupportsReplyTo"
          :in-reply-to="getInReplyToMessage(message)"
        />
      </template>
      
      <!-- Normal read messages -->
      <Message
        v-for="message in readMessages"
        :key="`read-${message.id}-${messagesKey}`"
        :set="logRenderedMessage(message, 'read')"
        class="message--read ph-no-capture"
        data-clarity-mask="True"
        :data="message"
        :is-a-tweet="isATweet"
        :is-a-whatsapp-channel="isAWhatsAppChannel"
        :is-web-widget-inbox="isAWebWidgetInbox"
        :is-a-facebook-inbox="isAFacebookInbox"
        :is-an-email-inbox="isAnEmailChannel"
        :is-instagram="isInstagramDM"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :in-reply-to="getInReplyToMessage(message)"
      />
      
      <!-- Unread notification toast -->
      <li v-show="unreadMessageCount != 0" class="unread--toast">
        <span>
          {{ unreadMessageCount > 9 ? '9+' : unreadMessageCount }}
          {{
            unreadMessageCount > 1
              ? $t('CONVERSATION.UNREAD_MESSAGES')
              : $t('CONVERSATION.UNREAD_MESSAGE')
          }}
        </span>
      </li>
      
      <!-- Normal unread messages -->
      <Message
        v-for="message in unReadMessages"
        :key="`unread-${message.id}-${messagesKey}`"
        :set="logRenderedMessage(message, 'unread')"
        class="message--unread ph-no-capture"
        data-clarity-mask="True"
        :data="message"
        :is-a-tweet="isATweet"
        :is-a-whatsapp-channel="isAWhatsAppChannel"
        :is-web-widget-inbox="isAWebWidgetInbox"
        :is-a-facebook-inbox="isAFacebookInbox"
        :is-instagram-dm="isInstagramDM"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :in-reply-to="getInReplyToMessage(message)"
      />
      
      <ConversationLabelSuggestion
        v-if="shouldShowLabelSuggestions"
        :suggested-labels="labelSuggestions"
        :chat-labels="currentChat.labels"
        :conversation-id="currentChat.id"
      />
    </ul>
    <div
      class="conversation-footer"
      :class="{
        'modal-mask': isPopOutReplyBox,
        'bg-n-background': showNextBubbles && !isPopOutReplyBox,
      }"
    >
      <div
        v-if="isAnyoneTyping"
        class="absolute flex items-center w-full h-0 -top-7"
      >
        <div
          class="flex py-2 pr-4 pl-5 shadow-md rounded-full bg-white dark:bg-slate-700 text-n-slate-11 text-xs font-semibold my-2.5 mx-auto"
        >
          {{ typingUserNames }}
          <img
            class="w-6 ltr:ml-2 rtl:mr-2"
            src="assets/images/typing.gif"
            alt="Someone is typing"
          />
        </div>
      </div>
      <ReplyBox
        v-model:popout-reply-box="isPopOutReplyBox"
        @toggle-popout="showPopOutReplyBox"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.modal-mask {
  @apply absolute;

  &::v-deep {
    .ProseMirror-woot-style {
      @apply max-h-[25rem];
    }

    .reply-box {
      @apply border border-n-weak max-w-[75rem] w-[70%];

      &.is-private {
        @apply dark:border-n-amber-3/30 border-n-amber-12/5;
      }
    }

    .reply-box .reply-box__top {
      @apply relative min-h-[27.5rem];
    }

    .reply-box__top .input {
      @apply min-h-[27.5rem];
    }

    .emoji-dialog {
      @apply absolute left-auto bottom-1;
    }
  }
}
</style>

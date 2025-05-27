import {
  createConversationAPI,
  sendMessageAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
  toggleStatus,
  setCustomAttributes,
  deleteCustomAttribute,
} from 'widget/api/conversation';

import { ON_CONVERSATION_CREATED } from 'widget/constants/widgetBusEvents';
import { createTemporaryMessage, getNonDeletedMessages } from './helpers';
import { emitter } from 'shared/helpers/mitt';

export const actions = {
  createConversation: async ({ commit, dispatch, state }, params) => {
    console.log('[🔍 Chatwoot Debug] Creating conversation with params:', {
      hasMessage: !!params.message,
      messageContent: params.message?.substring(0, 50) + '...',
      fullName: params.fullName,
      emailAddress: params.emailAddress
    });
    
    // Prevent multiple conversation creation calls
    if (state.uiFlags.isCreating) {
      console.log('[🔍 Chatwoot Debug] Conversation creation already in progress, skipping...');
      return;
    }
    
    commit('setConversationUIFlag', { isCreating: true });
    try {
      const { data } = await createConversationAPI(params);
      const { messages } = data;
      const [message = {}] = messages;
      
      console.log('[🔍 Chatwoot Debug] Conversation created successfully:', {
        conversationId: data.id,
        hasMessages: messages?.length > 0,
        messageCount: messages?.length || 0,
        firstMessageId: message?.id
      });
      
      commit('pushMessageToConversation', message);
      dispatch('conversationAttributes/getAttributes', {}, { root: true });
      emitter.emit(ON_CONVERSATION_CREATED);
    } catch (error) {
      console.error('[🔍 Chatwoot Debug] Conversation creation failed:', error.message);
    } finally {
      commit('setConversationUIFlag', { isCreating: false });
    }
  },

  sendMessage: async ({ dispatch }, params) => {
    const { content, replyTo } = params;
    const message = createTemporaryMessage({ content, replyTo });
    dispatch('sendMessageWithData', message);
  },

  sendMessageWithData: async ({ commit, dispatch, getters }, message) => {
    const { id, content, replyTo, meta = {} } = message;

    commit('pushMessageToConversation', message);
    commit('updateMessageMeta', { id, meta: { ...meta, error: '' } });
    
    try {
      const { data } = await sendMessageAPI(content, replyTo);
      commit('pushMessageToConversation', { ...data, status: 'sent' });
    } catch (error) {
      if (error.response?.data?.code === 'NO_CONVERSATION') {
        console.log('[🔍 Chatwoot Debug] NO_CONVERSATION error received');
        
        // Check if we already have conversations - if so, this is a backend lookup issue
        const conversationSize = getters.getConversationSize;
        console.log('[🔍 Chatwoot Debug] Current conversation size:', conversationSize);
        
        if (conversationSize > 0) {
          console.error('[🔍 Chatwoot Debug] ❌ CRITICAL: Backend cannot find conversation that frontend knows exists!');
          console.error('[🔍 Chatwoot Debug] This indicates a conversation lookup issue in MessagesController');
          
          // Don't create a new conversation - show error instead
          commit('pushMessageToConversation', { ...message, status: 'failed' });
          commit('updateMessageMeta', {
            id,
            meta: { ...meta, error: 'Message sending failed - conversation lookup issue. Please refresh the page.' },
          });
          return;
        }
        
        console.log('[🔍 Chatwoot Debug] No conversations exist, this should not happen after widget is opened');
        
        // Only create conversation if we truly have no conversations
        try {
          console.log('[🔍 Chatwoot Debug] Creating new conversation for message');
          await dispatch('createConversation', {
            message: content,
            fullName: '',
            emailAddress: '',
            phoneNumber: '',
            customAttributes: {}
          });
          console.log('[🔍 Chatwoot Debug] New conversation created successfully');
        } catch (conversationError) {
          console.error('[🔍 Chatwoot Debug] Failed to create conversation:', conversationError.message);
          commit('pushMessageToConversation', { ...message, status: 'failed' });
          commit('updateMessageMeta', {
            id,
            meta: { ...meta, error: 'Failed to create conversation' },
          });
        }
      } else {
        commit('pushMessageToConversation', { ...message, status: 'failed' });
        commit('updateMessageMeta', {
          id,
          meta: { ...meta, error: error.response?.data?.error || 'Message sending failed' },
        });
      }
    }
  },

  setLastMessageId: async ({ commit }) => {
    commit('setLastMessageId');
  },

  sendAttachment: async ({ commit }, params) => {
    const { attachment: { thumbUrl, fileType }, meta = {} } = params;
    const attachment = {
      thumb_url: thumbUrl,
      data_url: thumbUrl,
      file_type: fileType,
      status: 'in_progress',
    };
    
    const tempMessage = createTemporaryMessage({
      attachments: [attachment],
      replyTo: params.replyTo,
    });
    
    commit('pushMessageToConversation', tempMessage);
    
    try {
      const { data } = await sendAttachmentAPI(params);
      commit('updateAttachmentMessageStatus', {
        message: data,
        tempId: tempMessage.id,
      });
      commit('pushMessageToConversation', { ...data, status: 'sent' });
    } catch (error) {
      commit('pushMessageToConversation', { ...tempMessage, status: 'failed' });
      commit('updateMessageMeta', {
        id: tempMessage.id,
        meta: { ...meta, error: 'Attachment upload failed' },
      });
    }
  },

  fetchOldConversations: async ({ commit }, { before } = {}) => {
    commit('setConversationListLoading', true);
    
    try {
      const { data } = await getMessagesAPI({ before });
      
      if (!data || (!data.payload && !Array.isArray(data))) {
        commit('setMessagesInConversation', []);
        return;
      }
      
      const payload = data.payload || data;
      const meta = data.meta || {};
      const formattedMessages = getNonDeletedMessages({ messages: payload });
      
      if (meta.contact_last_seen_at) {
        commit('conversation/setMetaUserLastSeenAt', meta.contact_last_seen_at, { root: true });
      }
      
      commit('setMessagesInConversation', formattedMessages);
    } catch (error) {
      if (error.response?.status === 500) {
        commit('setMessagesInConversation', []);
      } else {
        console.error('[Chatwoot] Failed to fetch conversations:', error.message);
      }
    } finally {
      commit('setConversationListLoading', false);
    }
  },

  syncLatestMessages: async ({ state, commit }) => {
    try {
      const { lastMessageId, conversations } = state;
      const { data } = await getMessagesAPI({ after: lastMessageId });

      const payload = data.payload || data;
      const meta = data.meta || {};
      const formattedMessages = getNonDeletedMessages({ messages: payload });
      
      const missingMessages = formattedMessages.filter(
        message => conversations?.[message.id] === undefined
      );
      
      if (!missingMessages.length) return;
      
      missingMessages.forEach(message => {
        conversations[message.id] = message;
      });
      
      const updatedConversation = Object.fromEntries(
        Object.entries(conversations).sort(
          (a, b) => a[1].created_at - b[1].created_at
        )
      );
      
      if (meta.contact_last_seen_at) {
        commit('conversation/setMetaUserLastSeenAt', meta.contact_last_seen_at, { root: true });
      }
      
      commit('setMissingMessagesInConversation', updatedConversation);
    } catch (error) {
      console.error('[Chatwoot] Failed to sync messages:', error.message);
    }
  },

  clearConversations: ({ commit }) => {
    commit('clearConversations');
  },

  addOrUpdateMessage: async ({ commit }, data) => {
    const { id, content_attributes } = data;
    if (content_attributes?.deleted) {
      commit('deleteMessage', id);
      return;
    }
    commit('pushMessageToConversation', data);
  },

  toggleAgentTyping({ commit }, data) {
    commit('toggleAgentTypingStatus', data);
  },

  toggleUserTyping: async (_, data) => {
    try {
      await toggleTyping(data);
    } catch (error) {
      // Silent fail for typing indicators
    }
  },

  setUserLastSeen: async ({ commit, getters: appGetters }) => {
    if (!appGetters.getConversationSize) return;

    const lastSeen = Date.now() / 1000;
    try {
      commit('setMetaUserLastSeenAt', lastSeen);
      await setUserLastSeenAt({ lastSeen });
    } catch (error) {
      // Silent fail for last seen updates
    }
  },

  clearVisitorData: () => {
    const storageKeys = ['cw_visitor_id', 'cw_conversation', 'cw_contact', 'chatwoot_webwidget_triggered_session'];
    storageKeys.forEach(key => {
      sessionStorage.removeItem(key);
      localStorage.removeItem(key);
    });
    
    // Clear cookies
    const cookieKeys = ['cw_conversation', 'cw_contact'];
    cookieKeys.forEach(key => {
      document.cookie = `${key}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
    });
  },

  resolveConversation: async ({ commit, dispatch }) => {
    try {
      await toggleStatus();
      commit('clearConversations'); 
      dispatch('conversationAttributes/clearConversationAttributes', {}, { root: true }); 
      dispatch('clearVisitorData');
      
      // Clear webwidget triggered session flag to allow new webhook for next conversation
      sessionStorage.removeItem('chatwoot_webwidget_triggered_session');
      console.log('[Chatwoot] Cleared webwidget triggered session flag for next conversation');
      
      if (window.$chatwoot?.reset) {
        window.$chatwoot.reset(); 
      }
    } catch (error) {
      console.error('[Chatwoot] Error resolving conversation:', error.message);
    }
  },

  setCustomAttributes: async (_, customAttributes = {}) => {
    try {
      await setCustomAttributes(customAttributes);
    } catch (error) {
      console.error('[Chatwoot] Failed to set custom attributes:', error.message);
    }
  },

  deleteCustomAttribute: async (_, customAttribute) => {
    try {
      await deleteCustomAttribute(customAttribute);
    } catch (error) {
      console.error('[Chatwoot] Failed to delete custom attribute:', error.message);
    }
  },
};
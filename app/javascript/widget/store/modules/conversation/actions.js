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
import { IFrameHelper } from 'widget/helpers/utils';

export const actions = {
  createConversation: async ({ commit, dispatch, state }, params) => {
    
    // Prevent multiple conversation creation calls
    if (state.uiFlags.isCreating) {
      return;
    }
    
    commit('setConversationUIFlag', { isCreating: true });
    try {
      const { data } = await createConversationAPI(params);
      const { messages } = data;
      const [message = {}] = messages;
      
      commit('pushMessageToConversation', message);
      dispatch('conversationAttributes/getAttributes', {}, { root: true });
      emitter.emit(ON_CONVERSATION_CREATED);
      
      // Mark that a conversation now exists to prevent future webwidget.triggered events
      // Only set if not already set (to preserve the original timestamp from IFrameHelper)
      if (!sessionStorage.getItem('chatwoot_conversation_exists')) {
        sessionStorage.setItem('chatwoot_conversation_exists', Date.now().toString());
      } 
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
        
        // Check if we already have conversations - if so, this is a backend lookup issue
        const conversationSize = getters.getConversationSize;
        
        if (conversationSize > 0) {
          
          // Don't create a new conversation - show error instead
          commit('pushMessageToConversation', { ...message, status: 'failed' });
          commit('updateMessageMeta', {
            id,
            meta: { ...meta, error: 'Message sending failed - conversation lookup issue. Please refresh the page.' },
          });
          return;
        }
        
        // Only create conversation if we truly have no conversations
        try {
          await dispatch('createConversation', {
            message: content,
            fullName: '',
            emailAddress: '',
            phoneNumber: '',
            customAttributes: {}
          });
        } catch (conversationError) {
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
      
      // If we found existing conversations, mark that conversations exist to prevent webhooks
      // Only set if not already set (to preserve the original timestamp from IFrameHelper)
      if (formattedMessages && formattedMessages.length > 0) {
        if (!sessionStorage.getItem('chatwoot_conversation_exists')) {
          sessionStorage.setItem('chatwoot_conversation_exists', Date.now().toString());
          console.log('[Chatwoot] Found existing conversations - marked as existing to prevent duplicate webhooks');
        } else {
          console.log('[Chatwoot] Found existing conversations - already marked as existing (preserving original timestamp)');
        }
      }
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
    const storageKeys = ['cw_visitor_id', 'cw_conversation', 'cw_contact', 'chatwoot_webwidget_triggered_session', 'chatwoot_conversation_exists'];
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
      // First mark the conversation as resolved on the backend
      await toggleStatus(); // Let's assume this tells the backend the convo is ending
      // Now, clear the local state and reset the widget
      commit('clearConversations'); 
      dispatch('conversationAttributes/clearConversationAttributes', {}, { root: true }); 
      localStorage.removeItem('cw_conversation'); 
      localStorage.removeItem('cw_contact');    
      
      // Reset the widget state entirely
      window.$chatwoot.reset(); 
      
    } catch (error) {
      // Consider logging the error here instead of just ignoring
      console.error("Error in resolveConversation:", error);
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

import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const createConversationAPI = async content => {
  console.log('[Chatwoot Debug] API: Creating conversation with content:', content);
  const urlData = endPoints.createConversation(content);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    console.log('[Chatwoot Debug] API: Conversation created successfully:', response.data);
    return response;
  } catch (error) {
    console.error('[Chatwoot Debug] API: Conversation creation failed:', error);
    throw error;
  }
};

const sendMessageAPI = async (content, replyTo = null) => {
  console.log('[Chatwoot Debug] API: Sending message:', { content, replyTo });
  const urlData = endPoints.sendMessage(content, replyTo);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    console.log('[Chatwoot Debug] API: Message sent successfully:', response.data);
    return response;
  } catch (error) {
    console.error('[Chatwoot Debug] API: Message sending failed:', error);
    throw error;
  }
};

const sendAttachmentAPI = async (attachment, replyTo = null) => {
  console.log('[Chatwoot Debug] API: Sending attachment:', { attachment, replyTo });
  const urlData = endPoints.sendAttachment(attachment, replyTo);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    console.log('[Chatwoot Debug] API: Attachment sent successfully:', response.data);
    return response;
  } catch (error) {
    console.error('[Chatwoot Debug] API: Attachment sending failed:', error);
    throw error;
  }
};

const getMessagesAPI = async ({ before, after }) => {
  console.log('[Chatwoot Debug] API: Getting messages with params:', { before, after });
  const urlData = endPoints.getConversation({ before, after });
  
  try {
    const response = await API.get(urlData.url, { params: urlData.params });
    console.log('[Chatwoot Debug] API: Messages retrieved:', response.data?.length || 0, 'messages');
    return response;
  } catch (error) {
    console.error('[Chatwoot Debug] API: Messages retrieval failed:', error);
    throw error;
  }
};

const getConversationAPI = async () => {
  console.log('[Chatwoot Debug] API: Getting conversation');
  
  try {
    const response = await API.get(`/api/v1/widget/conversations${window.location.search}`);
    console.log('[Chatwoot Debug] API: Conversation retrieved:', {
      id: response.data?.id,
      status: response.data?.status,
      messagesCount: response.data?.messages?.length || 0
    });
    return response;
  } catch (error) {
    console.error('[Chatwoot Debug] API: Conversation retrieval failed:', error);
    throw error;
  }
};

const toggleTyping = async ({ typingStatus }) => {
  return API.post(
    `/api/v1/widget/conversations/toggle_typing${window.location.search}`,
    { typing_status: typingStatus }
  );
};

const setUserLastSeenAt = async ({ lastSeen }) => {
  return API.post(
    `/api/v1/widget/conversations/update_last_seen${window.location.search}`,
    { contact_last_seen_at: lastSeen }
  );
};
const sendEmailTranscript = async () => {
  return API.post(
    `/api/v1/widget/conversations/transcript${window.location.search}`
  );
};
const toggleStatus = async () => {
  return API.get(
    `/api/v1/widget/conversations/toggle_status${window.location.search}`
  );
};

const setCustomAttributes = async customAttributes => {
  return API.post(
    `/api/v1/widget/conversations/set_custom_attributes${window.location.search}`,
    {
      custom_attributes: customAttributes,
    }
  );
};

const deleteCustomAttribute = async customAttribute => {
  return API.post(
    `/api/v1/widget/conversations/destroy_custom_attributes${window.location.search}`,
    {
      custom_attribute: [customAttribute],
    }
  );
};

export {
  createConversationAPI,
  sendMessageAPI,
  getConversationAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
  sendEmailTranscript,
  toggleStatus,
  setCustomAttributes,
  deleteCustomAttribute,
};

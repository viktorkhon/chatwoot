import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';
import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';
import { getVisitorId } from '../helpers/utils';

const createConversationAPI = async content => {
  const urlData = endPoints.createConversation(content);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Conversation creation failed:', error);
    throw error;
  }
};

const sendMessageAPI = async (content, replyTo = null) => {
  const urlData = endPoints.sendMessage(content, replyTo);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Message sending failed:', error);
    throw error;
  }
};

const sendAttachmentAPI = async (attachment, replyTo = null) => {
  const urlData = endPoints.sendAttachment(attachment, replyTo);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Attachment sending failed:', error);
    throw error;
  }
};

const getMessagesAPI = async ({ before, after }) => {
  const urlData = endPoints.getConversation({ before, after });
  
  try {
    const response = await API.get(urlData.url, { params: urlData.params });
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Messages retrieval failed:', error);
    throw error;
  }
};

const getConversationAPI = async () => {
  const search = buildSearchParamsWithLocale(window.location.search);
  const visitorId = getVisitorId();
  
  try {
    const response = await API.get(`/api/v1/widget/conversations${search}`, {
      params: { visitor_id: visitorId }
    });
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Conversation retrieval failed:', error);
    throw error;
  }
};

const toggleTyping = async ({ typingStatus }) => {
  const urlData = endPoints.toggleTyping(typingStatus);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Toggle typing failed:', error);
    throw error;
  }
};

const setUserLastSeenAt = async ({ lastSeen }) => {
  const urlData = endPoints.updateLastSeen(lastSeen);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Update last seen failed:', error);
    throw error;
  }
};

const sendEmailTranscript = async () => {
  const urlData = endPoints.sendEmailTranscript();
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Send email transcript failed:', error);
    throw error;
  }
};

const toggleStatus = async () => {
  const urlData = endPoints.toggleStatus();
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Toggle status failed:', error);
    throw error;
  }
};

const setCustomAttributes = async customAttributes => {
  const urlData = endPoints.setCustomAttributes(customAttributes);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Set custom attributes failed:', error);
    throw error;
  }
};

const deleteCustomAttribute = async customAttribute => {
  const urlData = endPoints.deleteCustomAttribute(customAttribute);
  
  try {
    const response = await API.post(urlData.url, urlData.params);
    return response;
  } catch (error) {
    console.error('[Chatwoot] API: Delete custom attribute failed:', error);
    throw error;
  }
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

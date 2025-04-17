import { getAPI } from 'widget/helpers/axios';

export const createCustomCard = async ({
  conversationId,
  accountId,
  customCards,
  private: isPrivate = false,
}) => {
  try {
    const response = await getAPI().post(`/api/v1/accounts/${accountId}/conversations/${conversationId}/custom_cards`, {
      custom_cards: customCards,
      private: isPrivate,
    });
    return response.data;
  } catch (error) {
    throw new Error(error);
  }
};

export const updateCustomCard = async ({
  conversationId,
  accountId,
  customCardId,
  customCards,
}) => {
  try {
    const response = await getAPI().patch(
      `/api/v1/accounts/${accountId}/conversations/${conversationId}/custom_cards/${customCardId}`,
      {
        custom_cards: customCards,
      }
    );
    return response.data;
  } catch (error) {
    throw new Error(error);
  }
};

export const deleteCustomCard = async ({
  conversationId,
  accountId,
  customCardId,
}) => {
  try {
    const response = await getAPI().delete(
      `/api/v1/accounts/${accountId}/conversations/${conversationId}/custom_cards/${customCardId}`
    );
    return response.data;
  } catch (error) {
    throw new Error(error);
  }
}; 
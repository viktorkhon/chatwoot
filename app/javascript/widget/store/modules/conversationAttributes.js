import {
  SET_CONVERSATION_ATTRIBUTES,
  UPDATE_CONVERSATION_ATTRIBUTES,
  CLEAR_CONVERSATION_ATTRIBUTES,
} from '../types';
import { getConversationAPI } from '../../api/conversation';

const state = {
  id: null,
  status: '',
  assignee: null,
  team: null,
};

export const getters = {
  getConversationParams: $state => $state,
};

export const actions = {
  getAttributes: async ({ commit }) => {
    try {
      const { data } = await getConversationAPI();
      const { contact_last_seen_at: lastSeen } = data;
      commit(SET_CONVERSATION_ATTRIBUTES, data);
      commit('conversation/setMetaUserLastSeenAt', lastSeen, { root: true });
    } catch (error) {
      // Ignore error
    }
  },
  update({ commit }, data) {
    commit(UPDATE_CONVERSATION_ATTRIBUTES, data);
  },
  clearConversationAttributes: ({ commit }) => {
    commit('CLEAR_CONVERSATION_ATTRIBUTES');
  },
};

export const mutations = {
  [SET_CONVERSATION_ATTRIBUTES]($state, apiResponseData) {
    Object.assign($state, apiResponseData);
  },
  [UPDATE_CONVERSATION_ATTRIBUTES]($state, updatedData) {
    if (updatedData.id === $state.id) {
      Object.assign($state, updatedData);
    }
  },
  [CLEAR_CONVERSATION_ATTRIBUTES]($state) {
    $state.id = null;
    $state.status = '';
    $state.assignee = null;
    $state.team = null;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};

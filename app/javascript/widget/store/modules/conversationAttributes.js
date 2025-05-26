import {
  SET_CONVERSATION_ATTRIBUTES,
  UPDATE_CONVERSATION_ATTRIBUTES,
  CLEAR_CONVERSATION_ATTRIBUTES,
} from '../types';
import { getConversationAPI } from '../../api/conversation';

const state = {
  id: '',
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
      const lastSeen = data.contact_last_seen_at;
      commit(SET_CONVERSATION_ATTRIBUTES, data);
      if (lastSeen) {
        commit('conversation/setMetaUserLastSeenAt', lastSeen, { root: true });
      }
    } catch (error) {
      console.error('[Chatwoot] Failed to get conversation attributes:', error);
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
  [SET_CONVERSATION_ATTRIBUTES]($state, data) {
    $state.id = data.id;
    $state.status = data.status;
    $state.assignee = data.assignee;
    $state.team = data.team;
  },
  [UPDATE_CONVERSATION_ATTRIBUTES]($state, data) {
    if (data.id === $state.id) {
      $state.id = data.id;
      $state.status = data.status;
      $state.assignee = data.assignee;
      $state.team = data.team;
    }
  },
  [CLEAR_CONVERSATION_ATTRIBUTES]($state) {
    $state.id = '';
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

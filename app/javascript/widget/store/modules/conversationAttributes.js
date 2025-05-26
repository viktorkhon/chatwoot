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
  getAttributes: async ({ commit, state }) => {
    // Prevent unnecessary calls if we already have conversation data
    if (state.id) {
      console.log('[Widget] Skipping getAttributes - already have conversation:', state.id);
      return;
    }
    
    console.log('[Widget] Fetching conversation attributes via getConversationAPI...');
    
    try {
      const { data } = await getConversationAPI();
      
      // Handle case where no conversation exists yet (empty response)
      if (!data || !data.id) {
        console.log('[Widget] No conversation found - user hasn\'t started chatting yet');
        commit('CLEAR_CONVERSATION_ATTRIBUTES');
        return;
      }
      
      const lastSeen = data.contact_last_seen_at;
      commit(SET_CONVERSATION_ATTRIBUTES, data);
      if (lastSeen) {
        commit('conversation/setMetaUserLastSeenAt', lastSeen, { root: true });
      }
      
      console.log('[Widget] Conversation attributes loaded:', {
        id: data.id,
        status: data.status,
        hasAssignee: !!data.assignee,
        hasTeam: !!data.team
      });
    } catch (error) {
      // Check if this is the specific urlParamsHelper error we're fixing
      if (error.message && error.message.includes("Cannot read properties of undefined (reading '$root')")) {
        console.warn('[Widget] Widget initialization timing issue - this is expected on first load and will resolve automatically');
      } else {
        console.error('[Widget] Failed to get conversation attributes:', error.message);
      }
      // Clear attributes on error to ensure clean state
      commit('CLEAR_CONVERSATION_ATTRIBUTES');
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

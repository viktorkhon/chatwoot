import events from 'widget/api/events';

const actions = {
  create: async (_, { name }) => {
    try {
      await events.create(name);
      // Mark session as triggered for webwidget.triggered events to prevent duplicates
      if (name === 'webwidget.triggered') {
        sessionStorage.setItem('chatwoot_webwidget_triggered_session', Date.now().toString());
      }
    } catch (error) {
      // Ignore error
    }
  },
};

export default {
  namespaced: true,
  state: {},
  getters: {},
  actions,
  mutations: {},
};

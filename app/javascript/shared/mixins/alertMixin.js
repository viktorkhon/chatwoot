export default {
  methods: {
    showAlert(title, message, type = 'success') {
      this.$store.dispatch('notifications/add', {
        type,
        title,
        message,
        primaryAction: null,
        secondaryAction: null,
      });
    },
  },
}; 
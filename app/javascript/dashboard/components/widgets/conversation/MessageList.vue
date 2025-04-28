<template>
  <!-- No changes to template section -->
</template>

<script>
export default {
  mounted() {
    // Existing code...
    
    // Auto-fix custom cards after messages are loaded
    setTimeout(() => {
      if (window.fixAllCustomCardMessages) {
        console.log('Auto-running fixAllCustomCardMessages');
        window.fixAllCustomCardMessages();
      }
    }, 1000);
  },
};
</script>

<style>
  /* No changes to style section */
</style> 
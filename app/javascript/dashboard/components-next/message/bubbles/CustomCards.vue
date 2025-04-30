<script setup>
import { computed } from 'vue';
// Import the shared component responsible for rendering the visual card layout
import CustomCard from 'dashboard/components/widgets/conversation/bubble/CustomCard.vue';

// Define component properties
const props = defineProps({
  // Message content (though not typically used directly by custom cards)
  content: {
    type: String,
    default: '',
  },
  // Object containing message attributes, expected to have an 'items' array for custom cards
  contentAttributes: {
    type: Object,
    default: () => ({}),
  },
});

// Compute the 'items' array from contentAttributes
// This isolates the card data needed by the CustomCard component
const items = computed(() => {
  // Log the received attributes for debugging
  console.log('[CustomCards] contentAttributes:', props.contentAttributes);
  // Safely extract the 'items' array, defaulting to an empty array if it doesn't exist
  const result = props.contentAttributes?.items || [];
  // Log the extracted items for debugging
  console.log('[CustomCards] items:', result);
  return result;
});
</script>

<template>
  <!-- Wrapper div for the custom cards -->
  <div class="custom-cards-wrapper">
    <!-- Render the shared CustomCard component, passing the extracted items -->
    <!-- The CustomCard component handles the display logic for each item in the array -->
    <CustomCard :items="items" />
  </div>
</template>

<style lang="scss" scoped>
.custom-cards-wrapper {
  @apply flex flex-col gap-2 w-full;
}
</style> 
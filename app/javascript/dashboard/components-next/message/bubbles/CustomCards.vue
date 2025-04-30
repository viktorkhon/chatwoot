<script setup>
import { computed } from 'vue';
// Import the shared component responsible for rendering the visual card layout
import CustomCard from 'dashboard/components/widgets/conversation/bubble/CustomCard.vue';

/**
 * CustomCardsBubble Component
 * 
 * This component serves as a wrapper/adapter between the Message component and the
 * CustomCard display component. Its main responsibilities are:
 * 1. Extract the items array from contentAttributes (handling both camel and snake case)
 * 2. Pass these items to the CustomCard component for rendering
 * 
 * This component handles the data format differences between the API response and what
 * the CustomCard component expects.
 */

// Define component properties
const props = defineProps({
  // Message content (though not typically used directly by custom cards)
  content: {
    type: String,
    default: '',
  },
  // Object containing message attributes in camelCase format 
  // (from transformation in MessageList) - expected to have an 'items' array
  contentAttributes: {
    type: Object,
    default: () => ({}),
  },
  // Object containing message attributes in snake_case format
  // (preserved from original API response) - expected to have an 'items' array
  content_attributes: {
    type: Object,
    default: () => ({}),
  },
});

/**
 * Extract card items from either camelCase or snake_case content attributes.
 * This ensures compatibility regardless of how the data is transformed.
 * 
 * @returns {Array} - Array of card items to be displayed
 */
const items = computed(() => {
  // Check both camelCase and snake_case versions
  const camelCaseItems = props.contentAttributes?.items || [];
  const snakeCaseItems = props.content_attributes?.items || [];
  
  // Use whichever is non-empty, preferring camelCase if both have items
  const result = camelCaseItems.length ? camelCaseItems : snakeCaseItems;
  
  // Only log errors when both are missing items or debug info when we have items
  if (!camelCaseItems.length && !snakeCaseItems.length) {
    console.warn('[CustomCards] No items found in either contentAttributes or content_attributes');
  } else if (result.length) {
    console.info(`[CustomCards] Found ${result.length} items to display`);
  }
  
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
  
  /* Add a subtle visual indicator when in dev mode */
  &::before {
    content: '';
    @apply h-1 w-full bg-gradient-to-r from-transparent via-green-100 to-transparent;
  }
}
</style> 
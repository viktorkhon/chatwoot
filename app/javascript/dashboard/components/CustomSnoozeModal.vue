<script>
import WootModal from 'dashboard/components/modal/Modal.vue';
import WootButton from 'dashboard/components-next/button/Button.vue';
import DateTimePicker from 'dashboard/components/DateTimePicker.vue';
import { addDays, addHours, startOfTomorrow, startOfDay, addWeeks } from 'date-fns';

export default {
  components: {
    WootModal,
    WootButton,
    DateTimePicker,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    conversationId: {
      type: [String, Number],
      default: null,
    },
  },
  emits: ['close', 'snooze'],
  data() {
    return {
      showCustomDatePicker: false,
      customDateTime: new Date(),
      snoozeOptions: [
        {
          id: 'until_next_reply',
          label: 'CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.NEXT_REPLY',
          value: null,
        },
        {
          id: 'an_hour_from_now',
          label: 'COMMAND_BAR.COMMANDS.AN_HOUR_FROM_NOW',
          value: () => addHours(new Date(), 1),
        },
        {
          id: 'until_tomorrow',
          label: 'CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.TOMORROW',
          value: () => startOfTomorrow(),
        },
        {
          id: 'until_next_week',
          label: 'CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.NEXT_WEEK',
          value: () => addWeeks(startOfDay(new Date()), 1),
        },
      ],
    };
  },
  methods: {
    onClose() {
      this.showCustomDatePicker = false;
      this.$emit('close');
    },
    selectOption(optionId) {
      const option = this.snoozeOptions.find(o => o.id === optionId);
      if (!option) return;
      
      let snoozedUntil = null;
      if (option.value) {
        snoozedUntil = option.value();
      }
      
      this.$emit('snooze', this.conversationId, 'snoozed', snoozedUntil);
      this.onClose();
    },
    selectCustomOption() {
      if (!this.customDateTime) return;
      
      this.$emit('snooze', this.conversationId, 'snoozed', this.customDateTime);
      this.onClose();
    },
  },
};
</script>

<template>
  <teleport to="#custom-snooze-modal">
    <woot-modal :show.sync="show" :on-close="onClose">
      <div class="p-4">
        <div class="mb-4">
          <h3 class="text-lg font-medium leading-6 text-slate-900 dark:text-slate-100">
            {{ $t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.TITLE') }}
          </h3>
        </div>
        <div class="flex flex-col space-y-2">
          <woot-button
            v-for="option in snoozeOptions"
            :key="option.id"
            variant="clear"
            color="slate"
            sm
            class="w-full justify-start"
            @click="selectOption(option.id)"
          >
            {{ $t(option.label) }}
          </woot-button>
          <woot-button
            variant="clear"
            color="slate"
            sm
            class="w-full justify-start"
            @click="showCustomDatePicker = true"
          >
            {{ $t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE.CUSTOM') }}
          </woot-button>
        </div>
        <div v-if="showCustomDatePicker" class="mt-4">
          <div class="flex items-center space-x-2">
            <date-time-picker v-model="customDateTime" class="flex-1" />
            <woot-button variant="primary" size="small" @click="selectCustomOption">
              {{ $t('CONVERSATION.CUSTOM_SNOOZE.APPLY') }}
            </woot-button>
          </div>
        </div>
      </div>
    </woot-modal>
  </teleport>
</template>

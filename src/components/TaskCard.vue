<template>
  <div class="task-card fade-up"
    :class="['priority-' + task.priority, { done: task.done }]"
    draggable="true"
    @dragstart="$emit('dragstart', task.id)"
    @dragend="$emit('dragend')"
    @click="$emit('click', task)">
    <div class="flex items-start gap-2 mb-2">
      <div class="checkbox-custom mt-0.5" :class="{ checked: task.done }"
        @click.stop="$emit('toggle-done', task.id)">
        <svg v-if="task.done" width="10" height="8" viewBox="0 0 10 8" fill="none"><path d="M1 4l3 3 5-6" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
      </div>
      <div class="flex-1 min-w-0">
        <div class="task-title text-sm font-medium leading-snug">{{ task.title }}</div>
        <div v-if="task.desc" class="text-xs mt-1 truncate" style="color:var(--muted)">{{ task.desc }}</div>
      </div>
    </div>
    <div class="flex items-center justify-between mt-3">
      <div class="flex items-center gap-2">
        <template v-if="member">
          <div class="avatar" :style="{ background: member.color, color: '#000' }">
            {{ member.name.slice(0, 2).toUpperCase() }}
          </div>
        </template>
        <span v-if="task.due" class="text-xs font-mono"
          :class="{ 'text-red-400': overdue }"
          :style="overdue ? '' : 'color:var(--muted)'">
          {{ overdue ? '⚠ ' : '' }}{{ task.due }}
        </span>
      </div>
      <div class="flex items-center gap-1">
        <svg v-if="hasReminder" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#e8ff47" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        <div class="rounded-full" style="width:6px;height:6px" :style="{ background: priorityDot }"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { priorityDotColor, isOverdue } from '../utils.js'

const props = defineProps({
  task: Object,
  member: Object,
  hasReminder: Boolean,
})
defineEmits(['dragstart', 'dragend', 'click', 'toggle-done'])

const overdue    = computed(() => isOverdue(props.task))
const priorityDot = computed(() => priorityDotColor(props.task.priority))
</script>

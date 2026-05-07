<template>
  <div>
    <div class="flex gap-4 overflow-x-auto pb-4">
      <div v-for="col in columns" :key="col.status"
        class="column"
        :class="{ 'drag-over': dragOver === col.status }"
        @dragover.prevent="$emit('update:dragOver', col.status)"
        @dragleave="$emit('update:dragOver', null)"
        @drop.prevent="$emit('drop', col.status)">
        <div class="column-header">
          <div class="w-2 h-2 rounded-full flex-shrink-0" :style="{ background: col.dot }"></div>
          <span class="text-sm font-semibold">{{ col.label }}</span>
          <span class="ml-auto badge" :style="dotToBadgeStyle(col.dot)">{{ tasksByStatus(col.status).length }}</span>
        </div>
        <div class="p-3 flex flex-col gap-2">
          <div v-if="tasksByStatus(col.status).length === 0"
            class="text-center py-6 text-xs font-mono" style="color:var(--muted)">drop here</div>
          <TaskCard
            v-for="task in tasksByStatus(col.status)" :key="task.id"
            :task="task"
            :member="memberById(task.assigneeId)"
            :has-reminder="hasActiveReminder(task.id)"
            :can-drag="canDrag(task)"
            @dragstart="$emit('update:dragTaskId', $event)"
            @dragend="$emit('update:dragOver', null)"
            @click="$emit('open-detail', $event)"
            @toggle-done="$emit('toggle-done', $event)"
          />
        </div>
      </div>
    </div>

    <button
      v-if="showBackToTop"
      class="btn-ghost fixed bottom-6 right-6 z-[180] flex items-center gap-1.5"
      style="border-color:var(--accent);background:var(--surface)"
      title="Back to top"
      @click="scrollToTop"
    >
      <span class="material-icons" style="font-size:16px">keyboard_arrow_up</span>
      Top
    </button>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import TaskCard from './TaskCard.vue'
import { dotToBadgeStyle } from '../utils.js'

const props = defineProps({
  columns: Array,
  filteredTasks: Array,
  members: Array,
  reminders: Array,
  currentUser: Object,
  dragOver: String,
})
defineEmits(['update:dragOver', 'update:dragTaskId', 'drop', 'open-detail', 'toggle-done'])

const tasksByStatus     = (status) => props.filteredTasks.filter(t => t.status === status)
const memberById        = (id) => props.members.find(m => m.id === id)
const hasActiveReminder = (id) => props.reminders.some(r => r.taskId === id && !r.fired)
const canDrag           = (task) =>
  props.currentUser?.access === 'admin' || task.assigneeId === props.currentUser?.id

const showBackToTop = ref(false)

function onScroll() {
  showBackToTop.value = window.scrollY > 320
}

function scrollToTop() {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

onMounted(() => {
  onScroll()
  window.addEventListener('scroll', onScroll, { passive: true })
})

onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
})
</script>

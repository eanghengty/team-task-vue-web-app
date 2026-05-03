<template>
  <div class="modal-overlay" :class="{ open }" @click.self="$emit('close')">
    <div class="modal p-0" v-if="task">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-xl tracking-wider">TASK DETAIL</span>
          <button @click="$emit('close')" style="color:var(--muted);display:flex;align-items:center"><span class="material-icons" style="font-size:20px">close</span></button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <div class="flex items-center gap-2 mb-1">
            <div class="w-2 h-2 rounded-full" :style="{ background: priorityDotColor(task.priority) }"></div>
            <span class="font-semibold text-base" :class="{ 'line-through': task.done }" :style="task.done ? 'color:var(--muted)' : ''">{{ task.title }}</span>
          </div>
          <p v-if="task.desc" class="text-sm mt-2" style="color:#aaa">{{ task.desc }}</p>
        </div>
        <div class="grid grid-cols-2 gap-3 text-sm">
          <div class="p-3 rounded-lg" style="background:var(--surface2)">
            <div class="text-xs font-mono mb-1" style="color:var(--muted)">ASSIGNED TO</div>
            <div class="flex items-center gap-2">
              <div class="avatar" :style="{ background: assignee?.color || '#444', color: '#000' }">
                {{ assignee?.name?.slice(0, 2).toUpperCase() || '?' }}
              </div>
              <span>{{ assignee?.name || 'Unassigned' }}</span>
            </div>
          </div>
          <div class="p-3 rounded-lg" style="background:var(--surface2)">
            <div class="text-xs font-mono mb-1" style="color:var(--muted)">DUE DATE</div>
            <div :class="{ 'text-red-400': overdue }">{{ task.due || '—' }}</div>
            <div v-if="overdue" class="text-xs text-red-400">Overdue!</div>
          </div>
          <div class="p-3 rounded-lg" style="background:var(--surface2)">
            <div class="text-xs font-mono mb-1" style="color:var(--muted)">PRIORITY</div>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 rounded-full" :style="{ background: priorityDotColor(task.priority) }"></div>
              {{ task.priority }}
            </div>
          </div>
          <div class="p-3 rounded-lg" style="background:var(--surface2)">
            <div class="text-xs font-mono mb-1" style="color:var(--muted)">STATUS</div>
            <div>{{ statusLabel(task.status) }}</div>
          </div>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary text-sm flex-1" @click="$emit('toggle-done', task.id); $emit('close')">
            {{ task.done ? 'Reopen' : 'Mark Done' }}
          </button>
          <button class="btn-ghost text-sm" style="color:var(--accent2);border-color:rgba(255,71,71,0.3)"
            @click="$emit('delete-task', task.id); $emit('close')">Delete</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { priorityDotColor, isOverdue } from '../utils.js'

const props = defineProps({
  open:    Boolean,
  task:    Object,
  members: Array,
  columns: Array,
})
defineEmits(['close', 'toggle-done', 'delete-task'])

const assignee    = computed(() => props.members.find(m => m.id === props.task?.assigneeId))
const overdue     = computed(() => props.task ? isOverdue(props.task) : false)
const statusLabel = (key) => props.columns?.find(c => c.status === key)?.label ?? key
</script>

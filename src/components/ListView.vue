<template>
  <div class="rounded-lg overflow-hidden" style="border:1px solid var(--border)">
    <table class="w-full text-sm">
      <thead>
        <tr style="background:var(--surface);border-bottom:1px solid var(--border)">
          <th v-for="h in ['DONE','TASK','ASSIGNED','DUE','PRIORITY','STATUS','ACTIONS']" :key="h"
            class="text-left p-3 font-mono text-xs" style="color:var(--muted)">{{ h }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="tasks.length === 0">
          <td colspan="7" class="text-center py-8 text-sm font-mono" style="color:var(--muted)">no tasks yet</td>
        </tr>
        <tr v-for="task in tasks" :key="task.id"
          class="border-b cursor-pointer hover:opacity-80 transition-opacity"
          style="border-color:var(--border);background:var(--surface)"
          @click="$emit('open-detail', task)">
          <td class="p-3">
            <div class="checkbox-custom" :class="{ checked: task.done }"
              :style="!canAct(task) ? 'opacity:0.4;cursor:not-allowed' : ''"
              @click.stop="canAct(task) && $emit('toggle-done', task.id)">
              <svg v-if="task.done" width="10" height="8" viewBox="0 0 10 8" fill="none"><path d="M1 4l3 3 5-6" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </div>
          </td>
          <td class="p-3">
            <div class="flex items-center gap-2">
              <span class="text-sm" :class="{ 'line-through': task.done }" :style="task.done ? 'color:var(--muted)' : ''">
                {{ task.title }}
              </span>
              <span v-if="task.confirmed === false"
                class="text-xs font-mono px-1.5 py-0.5 rounded flex-shrink-0"
                style="background:rgba(255,158,71,0.15);color:#ff9e47;font-size:9px">PENDING</span>
            </div>
          </td>
          <td class="p-3">
            <div class="flex items-center gap-2">
              <div v-if="memberById(task.assigneeId)" class="avatar overflow-hidden"
                :style="{ background: memberById(task.assigneeId).color, color: '#000', width:'22px', height:'22px', fontSize:'9px' }">
                <img
                  v-if="memberById(task.assigneeId).avatarUrl"
                  :src="memberById(task.assigneeId).avatarUrl"
                  :alt="memberById(task.assigneeId).name"
                  class="w-full h-full object-cover"
                />
                <span v-else>{{ memberById(task.assigneeId).name.slice(0, 2).toUpperCase() }}</span>
              </div>
              <span class="text-sm">{{ memberById(task.assigneeId)?.name || '—' }}</span>
            </div>
          </td>
          <td class="p-3 text-sm font-mono"
            :class="{ 'text-red-400': isOverdue(task) }"
            :style="!isOverdue(task) ? 'color:var(--muted)' : ''">{{ task.due || '—' }}</td>
          <td class="p-3">
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 rounded-full" :style="{ background: priorityDotColor(task.priority) }"></div>
              <span class="text-xs capitalize">{{ task.priority }}</span>
            </div>
          </td>
          <td class="p-3">
            <span class="badge" :style="statusStyle(task.status)">{{ statusLabel(task.status) }}</span>
          </td>
          <td class="p-3">
            <button @click.stop="$emit('delete-task', task.id)"
              class="text-xs font-mono hover:text-red-400 transition-colors" style="color:var(--muted)">del</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { isOverdue, priorityDotColor, dotToBadgeStyle } from '../utils.js'

const props = defineProps({
  tasks:       Array,
  members:     Array,
  columns:     Array,
  currentUser: Object,
})
defineEmits(['open-detail', 'toggle-done', 'delete-task'])

const memberById  = (id)  => props.members.find(m => m.id === id)
const colByStatus = (key) => props.columns?.find(c => c.status === key)
const statusLabel = (key) => colByStatus(key)?.label ?? key
const statusStyle = (key) => dotToBadgeStyle(colByStatus(key)?.dot ?? '#888888')
const canAct      = (task) =>
  props.currentUser?.access === 'admin' || task.assigneeId === props.currentUser?.id
</script>

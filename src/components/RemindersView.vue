<template>
  <div class="max-w-2xl">
    <div class="flex items-center justify-between mb-4">
      <h2 class="font-display text-2xl tracking-wider">REMINDERS</h2>
      <button @click="$emit('open-modal', 'reminder')" class="btn-primary text-xs">+ Add Reminder</button>
    </div>
    <div v-if="reminders.length === 0" class="text-center py-12">
      <div class="font-mono text-sm" style="color:var(--muted)">no reminders set</div>
    </div>
    <div v-else class="flex flex-col gap-3">
      <div v-for="r in reminders" :key="r.id" class="reminder-item" :class="{ 'opacity-50': r.fired }">
        <div class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center"
          :style="{ background: r.fired ? 'var(--surface)' : 'rgba(232,255,71,0.12)', border: '1px solid ' + (r.fired ? 'var(--border)' : 'rgba(232,255,71,0.3)') }">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" :stroke="r.fired ? 'var(--muted)' : 'var(--accent)'" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        </div>
        <div class="flex-1 min-w-0">
          <div class="text-sm font-medium" :class="{ 'line-through': r.fired }" :style="r.fired ? 'color:var(--muted)' : ''">{{ r.title }}</div>
          <div class="flex items-center gap-3 mt-1">
            <span class="text-xs font-mono"
              :class="{ 'text-red-400': isPast(r) }"
              :style="!isPast(r) ? 'color:var(--muted)' : ''">
              {{ new Date(r.datetime).toLocaleString() }}
            </span>
            <span v-if="linkedTask(r)" class="text-xs" style="color:var(--muted)">→ {{ linkedTask(r).title }}</span>
            <div v-if="reminderMember(r)" class="avatar"
              :style="{ background: reminderMember(r).color, color: '#000', width:'18px', height:'18px', fontSize:'8px' }">
              {{ reminderMember(r).name.slice(0, 2).toUpperCase() }}
            </div>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <span v-if="r.fired" class="badge badge-gray text-xs">fired</span>
          <button @click="$emit('delete-reminder', r.id)"
            class="hover:text-red-400 transition-colors" style="color:var(--muted);display:flex;align-items:center"><span class="material-icons" style="font-size:16px">close</span></button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  reminders: Array,
  tasks: Array,
  members: Array,
})
defineEmits(['open-modal', 'delete-reminder'])

const isPast         = (r) => !r.fired && new Date(r.datetime) < new Date()
const linkedTask     = (r) => r.taskId ? props.tasks.find(t => t.id === r.taskId) : null
const reminderMember = (r) => r.assigneeId && r.assigneeId !== 'team'
  ? props.members.find(m => m.id === r.assigneeId) : null
</script>

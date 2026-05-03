<template>
  <div class="px-6 py-4 flex gap-3 overflow-x-auto" style="border-bottom:1px solid var(--border)">
    <div class="stat-card flex items-center gap-3 flex-shrink-0">
      <span class="font-display text-3xl" style="color:var(--accent)">{{ tasks.length }}</span>
      <div><div class="text-xs font-mono" style="color:var(--muted)">TOTAL</div><div class="text-xs" style="color:var(--muted)">tasks</div></div>
    </div>
    <div class="stat-card flex items-center gap-3 flex-shrink-0">
      <span class="font-display text-3xl" style="color:#47c5ff">{{ openCount }}</span>
      <div><div class="text-xs font-mono" style="color:var(--muted)">OPEN</div><div class="text-xs" style="color:var(--muted)">pending</div></div>
    </div>
    <div class="stat-card flex items-center gap-3 flex-shrink-0">
      <span class="font-display text-3xl" style="color:#ff4747">{{ overdueCount }}</span>
      <div><div class="text-xs font-mono" style="color:var(--muted)">OVERDUE</div><div class="text-xs" style="color:var(--muted)">tasks</div></div>
    </div>
    <div class="stat-card flex-1 flex-shrink-0 min-w-48">
      <div class="flex justify-between items-center mb-2">
        <span class="text-xs font-mono" style="color:var(--muted)">PROGRESS</span>
        <span class="text-xs font-mono" style="color:var(--accent)">{{ progressPct }}%</span>
      </div>
      <div class="progress-bar"><div class="progress-fill" :style="{ width: progressPct + '%' }"></div></div>
    </div>
    <div class="stat-card flex items-center gap-2 flex-shrink-0 cursor-pointer"
      @click="$emit('open-modal', 'member')" style="border-color:rgba(232,255,71,0.2)">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <div>
        <div class="text-xs font-mono" style="color:var(--muted)">MEMBERS</div>
        <div class="text-xs" style="color:var(--accent)">{{ members.length }} active</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { isOverdue } from '../utils.js'

const props = defineProps({
  tasks: Array,
  members: Array,
})
defineEmits(['open-modal'])

const doneCount    = computed(() => props.tasks.filter(t => t.done || t.status === 'done').length)
const openCount    = computed(() => props.tasks.length - doneCount.value)
const overdueCount = computed(() => props.tasks.filter(t => isOverdue(t)).length)
const progressPct  = computed(() => props.tasks.length === 0 ? 0 : Math.round(doneCount.value / props.tasks.length * 100))
</script>

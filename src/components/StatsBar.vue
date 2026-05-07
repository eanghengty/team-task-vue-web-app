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
    <div
      class="stat-card flex items-center gap-2 flex-shrink-0 cursor-pointer"
      @click="showMemberPanel = true"
      style="border-color:rgba(232,255,71,0.2)"
    >
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <div>
        <div class="text-xs font-mono" style="color:var(--muted)">MEMBERS</div>
        <div class="text-xs" style="color:var(--accent)">{{ workspaceMembers.length }} in workspace</div>
      </div>
    </div>
  </div>
  <Teleport to="body">
    <div
      v-if="showMemberPanel"
      class="fixed inset-0 z-[360] flex items-center justify-center p-4"
      style="background:rgba(5,5,5,0.62)"
      @click="showMemberPanel = false"
    >
      <div
        class="w-[min(92vw,420px)] rounded-xl p-4"
        style="background:var(--surface2);border:1px solid var(--border);box-shadow:0 18px 44px rgba(0,0,0,0.42)"
        @click.stop
      >
        <div class="flex items-center justify-between mb-3">
          <div class="text-xs font-mono" style="color:var(--muted)">Workspace Members</div>
          <button
            type="button"
            class="w-7 h-7 rounded-full grid place-items-center"
            style="border:1px solid var(--border);color:var(--muted);background:var(--surface)"
            @click="showMemberPanel = false"
          >
            <span class="material-icons text-[16px]">close</span>
          </button>
        </div>
        <div v-if="workspaceMembers.length === 0" class="text-xs" style="color:var(--muted)">
          No members found.
        </div>
        <div v-else class="flex flex-col gap-2 max-h-[55vh] overflow-y-auto pr-1">
          <div
            v-for="m in workspaceMembers"
            :key="m.id"
            class="rounded-lg px-3 py-2"
            style="background:var(--surface);border:1px solid var(--border)"
          >
            <div class="text-sm font-medium truncate" style="color:var(--text)">{{ m.name }}</div>
            <div class="text-xs truncate" style="color:var(--muted)">{{ m.role || 'Team Member' }}</div>
            <div class="text-xs truncate" style="color:var(--muted)">{{ m.email || 'No email' }}</div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed, ref } from 'vue'
import { isOverdue } from '../utils.js'

const props = defineProps({
  tasks: Array,
  workspaceMembers: Array,
})
const showMemberPanel = ref(false)

const doneCount    = computed(() => props.tasks.filter(t => t.done || t.status === 'done').length)
const openCount    = computed(() => props.tasks.length - doneCount.value)
const overdueCount = computed(() => props.tasks.filter(t => isOverdue(t)).length)
const progressPct  = computed(() => props.tasks.length === 0 ? 0 : Math.round(doneCount.value / props.tasks.length * 100))
</script>

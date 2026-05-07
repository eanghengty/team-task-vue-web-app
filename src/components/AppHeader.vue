<template>
  <header class="header px-6 py-3 flex items-center justify-between sticky top-0 z-[100]"
    style="border-bottom:1px solid var(--border);background:rgba(13,13,13,0.9);backdrop-filter:blur(12px)">
    <div class="flex items-center gap-4">
      <span class="font-display text-3xl tracking-widest" style="color:var(--accent)">SQUAD</span>
      <span class="badge badge-gray font-mono text-xs">v2.0</span>
    </div>
    <div class="flex items-center gap-3">
      <div class="font-mono text-sm" style="color:var(--muted)">{{ clock }}</div>
      <div class="w-px h-5" style="background:var(--border)"></div>
      <select
        class="field text-xs"
        style="width:220px;padding:6px 10px"
        :value="currentWorkspaceId"
        @change="$emit('select-workspace', $event.target.value)"
      >
        <option v-for="w in workspaces" :key="w.id" :value="w.id">{{ w.name }}</option>
      </select>
      <button @click="$emit('open-workspace-modal')" class="btn-ghost flex items-center gap-1.5" title="Create Workspace">
        <span class="material-icons" style="font-size:16px">workspaces</span>
        Workspace
      </button>
      <button @click="$emit('open-modal', 'add')" class="btn-primary flex items-center gap-2">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
        New Task
      </button>
      <button @click="$emit('open-modal', 'reminder')" class="btn-ghost flex items-center gap-2">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        Reminders
      </button>
      <button @click="$emit('open-settings')" class="btn-ghost flex items-center gap-1.5" title="Settings">
        <span class="material-icons" style="font-size:16px">settings</span>
        Settings
      </button>

      <!-- notification bell -->
      <button @click="$emit('open-notifications')" class="btn-ghost flex items-center gap-1.5 relative" title="Notifications">
        <span class="material-icons" style="font-size:18px">notifications</span>
        <span v-if="unreadCount > 0"
          class="absolute flex items-center justify-center font-mono font-bold"
          style="top:-4px;right:-4px;min-width:16px;height:16px;padding:0 3px;border-radius:8px;font-size:9px;background:var(--accent2);color:#fff">
          {{ unreadCount > 99 ? '99+' : unreadCount }}
        </span>
      </button>

      <div class="w-px h-5" style="background:var(--border)"></div>

      <!-- current user chip -->
      <div class="flex items-center gap-2">
        <div class="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0"
          :style="{ background: currentUser.color, color: '#0d0d0d' }">
          {{ initials(currentUser.name) }}
        </div>
        <span class="text-sm font-medium hidden sm:block"
          style="max-width:120px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
          {{ currentUser.name }}
        </span>
      </div>
      <button @click="$emit('logout')" class="btn-ghost flex items-center gap-1.5" title="Sign out">
        <span class="material-icons" style="font-size:16px">logout</span>
      </button>
    </div>
  </header>
</template>

<script setup>
defineProps({
  clock: String,
  currentUser: Object,
  unreadCount: Number,
  workspaces: Array,
  currentWorkspaceId: String,
})
defineEmits([
  'open-modal',
  'open-settings',
  'open-notifications',
  'logout',
  'select-workspace',
  'open-workspace-modal',
])

function initials(name) {
  return (name || '?').split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase()
}
</script>

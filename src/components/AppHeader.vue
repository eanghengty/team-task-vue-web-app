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
      <button @click="$emit('open-modal', 'add')" class="btn-primary flex items-center gap-2">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
        New Task
      </button>
      <button @click="$emit('open-modal', 'reminder')" class="btn-ghost flex items-center gap-2">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        Reminders
      </button>
    </div>
  </header>
</template>

<script setup>
defineProps({ clock: String })
defineEmits(['open-modal'])
</script>

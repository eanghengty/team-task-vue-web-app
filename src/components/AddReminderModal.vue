<template>
  <div class="modal-overlay" :class="{ open }" @click.self="$emit('close')">
    <div class="modal p-0">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-2xl tracking-wider">{{ props.titleText || 'NEW REMINDER' }}</span>
          <button @click="$emit('close')" style="color:var(--muted)" class="hover:text-white">
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M1 1l16 16M17 1L1 17" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
          </button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">REMINDER TITLE *</label>
          <input class="field" v-model="form.title" placeholder="What should I remind you about?" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">LINKED TASK (optional)</label>
          <select class="field" v-model="form.taskId">
            <option value="">None</option>
            <option v-for="t in tasks" :key="t.id" :value="t.id">{{ t.title }}</option>
          </select>
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">REMIND AT *</label>
          <input class="field" v-model="form.datetime" type="datetime-local" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">NOTIFY</label>
          <select class="field" v-model="form.assigneeId">
            <option value="team">Whole Team</option>
            <option v-for="m in members" :key="m.id" :value="m.id">{{ m.name }}</option>
          </select>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary flex-1" @click="$emit('submit')">{{ props.submitText || 'Set Reminder' }}</button>
          <button class="btn-ghost" @click="$emit('close')">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  open: Boolean,
  form: Object,
  tasks: Array,
  members: Array,
  titleText: String,
  submitText: String,
})
defineEmits(['close', 'submit'])
</script>

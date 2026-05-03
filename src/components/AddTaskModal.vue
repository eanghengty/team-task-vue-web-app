<template>
  <div class="modal-overlay" :class="{ open }" @click.self="$emit('close')">
    <div class="modal p-0">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-2xl tracking-wider">NEW TASK</span>
          <button @click="$emit('close')" style="color:var(--muted)" class="hover:text-white">
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M1 1l16 16M17 1L1 17" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
          </button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">TASK TITLE *</label>
          <input class="field" :class="{ shake: shaking.taskTitle }" v-model="form.title" placeholder="What needs to be done?" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">DESCRIPTION</label>
          <textarea class="field" v-model="form.desc" rows="2" placeholder="Add details..."></textarea>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-mono mb-2" style="color:var(--muted)">ASSIGN TO *</label>
            <select class="field" :class="{ shake: shaking.taskAssignee }" v-model="form.assigneeId">
              <option value="">Select member...</option>
              <option v-for="m in members" :key="m.id" :value="m.id">{{ m.name }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-mono mb-2" style="color:var(--muted)">PRIORITY</label>
            <select class="field" v-model="form.priority">
              <option value="medium">Medium</option>
              <option value="high">High</option>
              <option value="low">Low</option>
            </select>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-mono mb-2" style="color:var(--muted)">DUE DATE</label>
            <input class="field" v-model="form.due" type="date" />
          </div>
          <div>
            <label class="block text-xs font-mono mb-2" style="color:var(--muted)">STATUS</label>
            <select class="field" v-model="form.status">
              <option v-for="col in columns" :key="col.status" :value="col.status">{{ col.label }}</option>
            </select>
          </div>
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">SET REMINDER</label>
          <input class="field" v-model="form.reminderDt" type="datetime-local" />
          <p class="text-xs mt-1" style="color:var(--muted)">Leave blank for no reminder</p>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary flex-1" @click="$emit('submit')">Create Task</button>
          <button class="btn-ghost" @click="$emit('close')">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  open:    Boolean,
  form:    Object,
  members: Array,
  columns: Array,
  shaking: Object,
})
defineEmits(['close', 'submit'])
</script>

<template>
  <div class="modal-overlay" :class="{ open }" @click.self="$emit('close')">
    <div class="modal p-0">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-2xl tracking-wider">NEW WORKSPACE</span>
          <button @click="$emit('close')" style="color:var(--muted)">
            <span class="material-icons" style="font-size:18px">close</span>
          </button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">WORKSPACE NAME *</label>
          <input class="field" v-model="name" placeholder="e.g. Product Team" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">MEMBERS</label>
          <div class="max-h-52 overflow-y-auto rounded-lg p-2" style="border:1px solid var(--border);background:var(--surface)">
            <label v-for="m in members" :key="m.id" class="flex items-center gap-2 px-2 py-1.5 cursor-pointer text-sm">
              <input type="checkbox" :checked="selectedIds.includes(m.id)" @change="toggleMember(m.id)" />
              <span>{{ m.name }}</span>
            </label>
          </div>
          <p class="text-xs mt-1" style="color:var(--muted)">You will always be included as owner.</p>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary flex-1" @click="submit">Create Workspace</button>
          <button class="btn-ghost" @click="$emit('close')">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  open: Boolean,
  members: Array,
  currentUser: Object,
})

const emit = defineEmits(['close', 'submit'])
const name = ref('')
const selectedIds = ref([])

watch(() => props.open, (val) => {
  if (val) {
    name.value = ''
    selectedIds.value = []
  }
})

function toggleMember(id) {
  if (selectedIds.value.includes(id)) {
    selectedIds.value = selectedIds.value.filter(x => x !== id)
  } else {
    selectedIds.value.push(id)
  }
}

function submit() {
  const cleanName = name.value.trim()
  if (!cleanName) return
  emit('submit', { name: cleanName, memberIds: selectedIds.value })
}
</script>

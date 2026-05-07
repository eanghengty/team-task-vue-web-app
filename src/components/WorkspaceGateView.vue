<template>
  <main class="min-h-screen flex items-center justify-center p-6" style="background:var(--bg)">
    <section class="w-full max-w-2xl rounded-xl p-6" style="background:var(--surface);border:1px solid var(--border)">
      <div class="flex items-center justify-between mb-5">
        <div>
          <h1 class="font-display text-3xl tracking-widest" style="color:var(--accent)">WORKSPACES</h1>
          <p class="text-sm mt-1" style="color:var(--muted)">
            {{ workspaces.length ? 'Select a workspace to continue' : 'Create your first workspace to continue' }}
          </p>
        </div>
        <button class="btn-ghost text-xs" @click="$emit('logout')">Logout</button>
      </div>

      <div v-if="loading" class="flex items-center justify-center py-16">
        <span class="material-icons animate-spin" style="color:var(--muted);font-size:32px">refresh</span>
      </div>

      <template v-else>
        <div v-if="workspaces.length" class="flex flex-col gap-4">
          <label class="text-xs font-mono" style="color:var(--muted)">CHOOSE WORKSPACE</label>
          <select class="field" v-model="selectedWorkspaceId">
            <option value="" disabled>Select workspace...</option>
            <option v-for="w in workspaces" :key="w.id" :value="w.id">{{ w.name }}</option>
          </select>
          <button class="btn-primary" :disabled="!selectedWorkspaceId" @click="continueWithWorkspace">Continue</button>
        </div>

        <div v-else class="flex flex-col gap-4">
          <label class="text-xs font-mono" style="color:var(--muted)">WORKSPACE NAME *</label>
          <input class="field" v-model="name" placeholder="e.g. Product Team" />

          <label class="text-xs font-mono" style="color:var(--muted)">MEMBERS</label>
          <div class="max-h-56 overflow-y-auto rounded-lg p-2" style="border:1px solid var(--border);background:var(--surface2)">
            <label v-for="m in members" :key="m.id" class="flex items-center gap-2 px-2 py-1.5 cursor-pointer text-sm">
              <input type="checkbox" :checked="selectedIds.includes(m.id)" @change="toggleMember(m.id)" />
              <span>{{ m.name }}</span>
            </label>
          </div>

          <button class="btn-primary" :disabled="!name.trim()" @click="createFirstWorkspace">Create Workspace</button>
        </div>
      </template>
    </section>
  </main>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  loading: Boolean,
  workspaces: Array,
  members: Array,
  currentUser: Object,
  suggestedWorkspaceId: String,
})

const emit = defineEmits(['select-workspace', 'create-workspace', 'logout'])

const selectedWorkspaceId = ref('')
const name = ref('')
const selectedIds = ref([])

watch(() => props.workspaces, (list) => {
  if (!list?.length) {
    selectedWorkspaceId.value = ''
    return
  }
  const suggestedValid = list.some(w => w.id === props.suggestedWorkspaceId)
  selectedWorkspaceId.value = suggestedValid ? props.suggestedWorkspaceId : list[0].id
}, { immediate: true })

function continueWithWorkspace() {
  if (!selectedWorkspaceId.value) return
  emit('select-workspace', selectedWorkspaceId.value)
}

function toggleMember(id) {
  if (selectedIds.value.includes(id)) {
    selectedIds.value = selectedIds.value.filter(x => x !== id)
  } else {
    selectedIds.value.push(id)
  }
}

function createFirstWorkspace() {
  const cleanName = name.value.trim()
  if (!cleanName) return
  emit('create-workspace', { name: cleanName, memberIds: selectedIds.value })
}
</script>

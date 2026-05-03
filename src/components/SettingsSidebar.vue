<template>
  <!-- Overlay -->
  <div
    class="fixed inset-0 z-[250] transition-opacity duration-200"
    :style="{ background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(2px)', opacity: open ? 1 : 0, pointerEvents: open ? 'all' : 'none' }"
    @click="$emit('close')"
  />

  <!-- Sidebar panel -->
  <div
    class="fixed top-0 right-0 h-full z-[260] flex flex-col transition-transform duration-300"
    style="width:420px;background:var(--surface);border-left:1px solid var(--border)"
    :style="{ transform: open ? 'translateX(0)' : 'translateX(100%)' }"
  >
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 flex-shrink-0" style="border-bottom:1px solid var(--border)">
      <div class="flex items-center gap-3">
        <span class="material-icons" style="color:var(--accent);font-size:20px">settings</span>
        <span class="font-display text-2xl tracking-widest">SETTINGS</span>
      </div>
      <button @click="$emit('close')" style="color:var(--muted);display:flex;align-items:center">
        <span class="material-icons" style="font-size:20px">close</span>
      </button>
    </div>

    <!-- Tab nav -->
    <div class="flex gap-1 px-6 py-3 flex-shrink-0" style="border-bottom:1px solid var(--border)">
      <button
        class="tab-btn"
        :class="{ active: activeTab === 'members' }"
        @click="activeTab = 'members'"
      >
        <span class="material-icons" style="font-size:15px;vertical-align:-3px;margin-right:5px">group</span>
        Members
      </button>
      <button
        class="tab-btn"
        :class="{ active: activeTab === 'statuses' }"
        @click="activeTab = 'statuses'"
      >
        <span class="material-icons" style="font-size:15px;vertical-align:-3px;margin-right:5px">view_kanban</span>
        Task Statuses
      </button>
    </div>

    <!-- Scrollable body -->
    <div class="flex-1 overflow-y-auto">

      <!-- ── MEMBERS TAB ─────────────────────────────────────── -->
      <div v-if="activeTab === 'members'" class="p-6 flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <p class="text-xs font-mono" style="color:var(--muted)">{{ members.length }} MEMBER{{ members.length !== 1 ? 'S' : '' }}</p>
          <button class="btn-primary flex items-center gap-1.5 text-xs px-3 py-1.5" @click="$emit('open-add-member')">
            <span class="material-icons" style="font-size:14px">person_add</span>
            Add Member
          </button>
        </div>

        <!-- Member rows -->
        <div v-for="m in members" :key="m.id" class="member-row">
          <!-- Editing state -->
          <template v-if="editingId === m.id">
            <div class="flex flex-col gap-3">
              <div class="flex items-center gap-3">
                <div class="avatar flex-shrink-0" :style="{ background: editForm.color, color: '#0d0d0d' }">
                  {{ initials(editForm.name) }}
                </div>
                <input class="field text-sm" v-model="editForm.name" placeholder="Full name" />
              </div>
              <input class="field text-sm" v-model="editForm.role" placeholder="Job role" />
              <div class="flex items-center gap-3">
                <div class="flex gap-1.5">
                  <div v-for="c in memberColors" :key="c"
                    class="w-6 h-6 rounded-full cursor-pointer"
                    :style="{ background: c, border: editForm.color === c ? '2px solid white' : '2px solid transparent' }"
                    @click="editForm.color = c"
                  />
                </div>
                <select class="field text-sm" style="width:auto;flex:1" v-model="editForm.access">
                  <option value="admin">Admin</option>
                  <option value="user">User</option>
                </select>
              </div>
              <div class="flex gap-2">
                <button class="btn-primary text-xs px-4 py-2 flex-1" @click="saveEdit(m.id)">Save</button>
                <button class="btn-ghost text-xs px-4 py-2" @click="editingId = null">Cancel</button>
              </div>
            </div>
          </template>

          <!-- View state -->
          <template v-else>
            <div class="flex items-center gap-3">
              <div class="avatar flex-shrink-0" :style="{ background: m.color, color: '#0d0d0d' }">
                {{ initials(m.name) }}
              </div>
              <div class="flex-1 min-w-0">
                <div class="font-medium text-sm truncate">{{ m.name }}</div>
                <div class="text-xs mt-0.5 truncate" style="color:var(--muted)">{{ m.role }}</div>
              </div>
              <span
                class="badge flex-shrink-0"
                :class="m.access === 'admin' ? 'badge-yellow' : 'badge-gray'"
              >{{ m.access }}</span>
              <div class="flex items-center gap-1 flex-shrink-0">
                <button class="icon-btn" title="Edit" @click="startEdit(m)">
                  <span class="material-icons" style="font-size:16px">edit</span>
                </button>
                <button class="icon-btn" title="Delete" style="color:var(--accent2)" @click="$emit('delete-member', m.id)">
                  <span class="material-icons" style="font-size:16px">delete</span>
                </button>
              </div>
            </div>
          </template>
        </div>

        <div v-if="!members.length" class="text-center py-12" style="color:var(--muted)">
          <span class="material-icons" style="font-size:40px;display:block;margin-bottom:8px">group_off</span>
          <p class="text-sm">No members yet</p>
        </div>
      </div>

      <!-- ── TASK STATUSES TAB ───────────────────────────────── -->
      <div v-if="activeTab === 'statuses'" class="p-6 flex flex-col gap-4">
        <p class="text-xs font-mono" style="color:var(--muted)">{{ columns.length }} STATUSES</p>

        <div v-for="col in columns" :key="col.status" class="member-row">
          <template v-if="editingStatusKey === col.status">
            <div class="flex flex-col gap-3">
              <div class="flex items-center gap-3">
                <input type="color" class="w-8 h-8 rounded cursor-pointer border-0 bg-transparent" v-model="statusEditForm.dot" />
                <input class="field text-sm" v-model="statusEditForm.label" placeholder="Label" />
              </div>
              <div class="flex gap-2">
                <button class="btn-primary text-xs px-4 py-2 flex-1" @click="saveStatusEdit(col.status)">Save</button>
                <button class="btn-ghost text-xs px-4 py-2" @click="editingStatusKey = null">Cancel</button>
              </div>
            </div>
          </template>
          <template v-else>
            <div class="flex items-center gap-3">
              <div class="w-3 h-3 rounded-full flex-shrink-0" :style="{ background: col.dot }" />
              <div class="flex-1">
                <div class="font-medium text-sm">{{ col.label }}</div>
                <div class="text-xs mt-0.5 font-mono" style="color:var(--muted)">{{ col.status }}</div>
              </div>
              <span class="badge badge-gray text-xs">{{ taskCountByStatus[col.status] ?? 0 }} tasks</span>
              <button class="icon-btn" title="Edit label & colour" @click="startStatusEdit(col)">
                <span class="material-icons" style="font-size:16px">edit</span>
              </button>
            </div>
          </template>
        </div>

        <p class="text-xs mt-2" style="color:var(--muted);line-height:1.6">
          Status keys are fixed by the database schema. You can rename labels and change dot colours here.
        </p>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'

const props = defineProps({
  open:        Boolean,
  members:     Array,
  columns:     Array,
  tasks:       Array,
  memberColors: Array,
})

const emit = defineEmits(['close', 'open-add-member', 'update-member', 'delete-member', 'update-status'])

const activeTab       = ref('members')
const editingId       = ref(null)
const editingStatusKey = ref(null)

const editForm = reactive({ name: '', role: '', color: '', access: 'user' })
const statusEditForm = reactive({ label: '', dot: '' })

const taskCountByStatus = computed(() => {
  const counts = {}
  for (const t of props.tasks) {
    counts[t.status] = (counts[t.status] ?? 0) + 1
  }
  return counts
})

function initials(name) {
  return (name || '?').split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase()
}

function startEdit(m) {
  editingId.value = m.id
  Object.assign(editForm, { name: m.name, role: m.role, color: m.color, access: m.access ?? 'user' })
}

function saveEdit(id) {
  emit('update-member', { id, ...editForm })
  editingId.value = null
}

function startStatusEdit(col) {
  editingStatusKey.value = col.status
  Object.assign(statusEditForm, { label: col.label, dot: col.dot })
}

function saveStatusEdit(status) {
  emit('update-status', { status, label: statusEditForm.label, dot: statusEditForm.dot })
  editingStatusKey.value = null
}
</script>

<style scoped>
.member-row {
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 14px 16px;
  transition: border-color 0.15s;
}
.member-row:hover { border-color: #3a3a3a; }

.icon-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: transparent;
  border: none;
  cursor: pointer;
  color: var(--muted);
  transition: background 0.15s, color 0.15s;
}
.icon-btn:hover { background: rgba(255,255,255,0.06); color: var(--text); }
</style>

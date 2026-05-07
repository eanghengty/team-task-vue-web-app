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
    style="width:440px;background:var(--surface);border-left:1px solid var(--border)"
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

    <!-- Tab nav (admin + workspace owners) -->
    <div v-if="showTabNav" class="flex gap-1 px-6 py-3 flex-shrink-0" style="border-bottom:1px solid var(--border)">
      <button class="tab-btn" :class="{ active: activeTab === 'members' }" @click="activeTab = 'members'">
        <span class="material-icons" style="font-size:15px;vertical-align:-3px;margin-right:5px">group</span>
        Members
      </button>
      <button class="tab-btn" :class="{ active: activeTab === 'statuses' }" @click="activeTab = 'statuses'">
        <span class="material-icons" style="font-size:15px;vertical-align:-3px;margin-right:5px">view_kanban</span>
        Task Statuses
      </button>
      <button class="tab-btn" :class="{ active: activeTab === 'workspaces' }" @click="activeTab = 'workspaces'">
        <span class="material-icons" style="font-size:15px;vertical-align:-3px;margin-right:5px">workspaces</span>
        Workspaces
      </button>
    </div>

    <!-- Scrollable body -->
    <div class="flex-1 overflow-y-auto">

      <!-- ── APPEARANCE (all users) ─────────────────────────────── -->
      <div class="px-6 py-4 flex items-center justify-between flex-shrink-0" style="border-bottom:1px solid var(--border)">
        <div>
          <div class="text-sm font-medium">Appearance</div>
          <div class="text-xs mt-0.5" style="color:var(--muted)">{{ isDark ? 'Dark mode' : 'Light mode' }}</div>
        </div>
        <button class="btn-ghost flex items-center gap-2 text-xs px-3 py-1.5" @click="$emit('toggle-theme')">
          <span class="material-icons" style="font-size:16px">{{ isDark ? 'light_mode' : 'dark_mode' }}</span>
          {{ isDark ? 'Light Mode' : 'Dark Mode' }}
        </button>
      </div>

      <!-- ── USER: Change Password only ─────────────────────────── -->
      <div v-if="showUserPasswordView" class="p-6 flex flex-col gap-4">
        <div>
          <div class="font-medium text-sm mb-0.5">Change Password</div>
          <div class="text-xs" style="color:var(--muted)">Update your login password</div>
        </div>

        <div class="member-row flex flex-col gap-3">
          <!-- Current user info (read-only) -->
          <div class="flex items-center gap-3 pb-3" style="border-bottom:1px solid var(--border)">
            <div class="avatar flex-shrink-0" :style="{ background: currentUser.color, color: '#0d0d0d' }">
              {{ initials(currentUser.name) }}
            </div>
            <div>
              <div class="font-medium text-sm">{{ currentUser.name }}</div>
              <div class="text-xs" style="color:var(--muted)">{{ currentUser.email }}</div>
            </div>
          </div>

          <div class="relative">
            <input
              class="field text-sm pr-10"
              :type="showNewPw ? 'text' : 'password'"
              v-model="newPassword"
              placeholder="New password"
              @keyup.enter="savePassword"
            />
            <button
              type="button"
              class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center"
              style="color:var(--muted)"
              @click="showNewPw = !showNewPw"
            >
              <span class="material-icons" style="font-size:16px">{{ showNewPw ? 'visibility_off' : 'visibility' }}</span>
            </button>
          </div>
          <div class="relative">
            <input
              class="field text-sm pr-10"
              :type="showConfirmPw ? 'text' : 'password'"
              v-model="confirmPassword"
              placeholder="Confirm new password"
              @keyup.enter="savePassword"
            />
            <button
              type="button"
              class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center"
              style="color:var(--muted)"
              @click="showConfirmPw = !showConfirmPw"
            >
              <span class="material-icons" style="font-size:16px">{{ showConfirmPw ? 'visibility_off' : 'visibility' }}</span>
            </button>
          </div>

          <div v-if="pwError" class="text-xs px-3 py-2 rounded-lg font-mono" style="background:rgba(255,71,71,0.12);color:var(--accent2);border:1px solid rgba(255,71,71,0.25)">
            {{ pwError }}
          </div>

          <button class="btn-primary text-xs px-4 py-2" @click="savePassword">Save Password</button>
        </div>
      </div>

      <!-- ── MEMBERS TAB (admin) ─────────────────────────────────── -->
      <div v-if="currentUser.access === 'admin' && activeTab === 'members'" class="p-6 flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <p class="text-xs font-mono" style="color:var(--muted)">{{ members.length }} MEMBER{{ members.length !== 1 ? 'S' : '' }}</p>
          <button class="btn-primary flex items-center gap-1.5 text-xs px-3 py-1.5" @click="$emit('open-add-member')">
            <span class="material-icons" style="font-size:14px">person_add</span>
            Add Member
          </button>
        </div>

        <!-- Member rows -->
        <div v-for="m in members" :key="m.id" class="member-row">

          <!-- ── Edit state ── -->
          <template v-if="editingId === m.id">
            <div class="flex flex-col gap-3">
              <!-- Avatar preview + name -->
              <div class="flex items-center gap-3">
                <div class="avatar flex-shrink-0" :style="{ background: editForm.color, color: '#0d0d0d' }">
                  {{ initials(editForm.name) }}
                </div>
                <input class="field text-sm" v-model="editForm.name" placeholder="Full name" />
              </div>

              <!-- Job role -->
              <input class="field text-sm" v-model="editForm.role" placeholder="Job role" />

              <!-- Email -->
              <input class="field text-sm" type="email" v-model="editForm.email" placeholder="Email address" />

              <!-- Password -->
              <div class="relative">
                <input
                  class="field text-sm pr-10"
                  :type="showEditPw ? 'text' : 'password'"
                  v-model="editForm.password"
                  placeholder="New password (leave blank to keep)"
                />
                <button
                  type="button"
                  class="absolute right-3 top-1/2 -translate-y-1/2"
                  style="color:var(--muted);display:flex;align-items:center"
                  @click="showEditPw = !showEditPw"
                >
                  <span class="material-icons" style="font-size:16px">{{ showEditPw ? 'visibility_off' : 'visibility' }}</span>
                </button>
              </div>

              <!-- Color + Access -->
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
                <button class="btn-ghost text-xs px-4 py-2" @click="cancelEdit">Cancel</button>
              </div>
            </div>
          </template>

          <!-- ── View state ── -->
          <template v-else>
            <div class="flex items-center gap-3">
              <div class="avatar flex-shrink-0" :style="{ background: m.color, color: '#0d0d0d' }">
                {{ initials(m.name) }}
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2">
                  <span class="font-medium text-sm truncate">{{ m.name }}</span>
                  <span class="badge flex-shrink-0" :class="m.access === 'admin' ? 'badge-yellow' : 'badge-gray'">
                    {{ m.access }}
                  </span>
                </div>
                <div class="text-xs mt-0.5 truncate" style="color:var(--muted)">{{ m.role }}</div>
                <div v-if="m.email" class="flex items-center gap-1 mt-1">
                  <span class="material-icons" style="font-size:12px;color:var(--muted)">mail</span>
                  <span class="text-xs truncate font-mono" style="color:var(--muted)">{{ m.email }}</span>
                </div>
                <div v-if="m.password" class="flex items-center gap-1 mt-0.5">
                  <span class="material-icons" style="font-size:12px;color:var(--muted)">lock</span>
                  <span class="text-xs font-mono" style="color:var(--muted)">
                    {{ revealPwId === m.id ? m.password : '••••••••' }}
                  </span>
                  <button
                    class="ml-1"
                    style="color:var(--muted);display:flex;align-items:center"
                    @click.stop="revealPwId = revealPwId === m.id ? null : m.id"
                  >
                    <span class="material-icons" style="font-size:13px">
                      {{ revealPwId === m.id ? 'visibility_off' : 'visibility' }}
                    </span>
                  </button>
                </div>
              </div>
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

      <!-- ── TASK STATUSES TAB (admin) ──────────────────────────── -->
      <div v-if="currentUser.access === 'admin' && activeTab === 'statuses'" class="p-6 flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <p class="text-xs font-mono" style="color:var(--muted)">{{ columns.length }} STATUSES</p>
          <button class="btn-primary flex items-center gap-1.5 text-xs px-3 py-1.5" @click="showAddStatus = !showAddStatus">
            <span class="material-icons" style="font-size:14px">{{ showAddStatus ? 'close' : 'add' }}</span>
            {{ showAddStatus ? 'Cancel' : 'Add Status' }}
          </button>
        </div>

        <!-- Add status form -->
        <div v-if="showAddStatus" class="member-row flex flex-col gap-3">
          <div class="flex items-center gap-3">
            <input type="color" class="w-9 h-9 rounded cursor-pointer border-0 bg-transparent flex-shrink-0" v-model="newStatusForm.dot" />
            <input class="field text-sm" v-model="newStatusForm.label" placeholder="Status label, e.g. In Review" @keyup.enter="submitAddStatus" />
          </div>
          <div v-if="newStatusForm.label" class="text-xs font-mono px-1" style="color:var(--muted)">
            key: {{ slugify(newStatusForm.label) }}
          </div>
          <button class="btn-primary text-xs px-4 py-2" @click="submitAddStatus">Add Status</button>
        </div>

        <!-- Status rows -->
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
              <div class="flex-1 min-w-0">
                <div class="font-medium text-sm">{{ col.label }}</div>
                <div class="text-xs mt-0.5 font-mono truncate" style="color:var(--muted)">{{ col.status }}</div>
              </div>
              <span class="badge badge-gray text-xs flex-shrink-0">{{ taskCountByStatus[col.status] ?? 0 }} tasks</span>
              <div class="flex items-center gap-1 flex-shrink-0">
                <button
                  class="icon-btn"
                  :title="col.isDone ? 'Done status' : 'Set as done status'"
                  :style="{ color: col.isDone ? 'var(--accent)' : 'var(--muted)' }"
                  @click="$emit('set-done-status', col.status)"
                >
                  <span class="material-icons" style="font-size:16px">{{ col.isDone ? 'task_alt' : 'radio_button_unchecked' }}</span>
                </button>
                <button
                  class="icon-btn"
                  title="Move up"
                  :style="{ opacity: columns.indexOf(col) === 0 ? 0.3 : 1, cursor: columns.indexOf(col) === 0 ? 'not-allowed' : 'pointer' }"
                  :disabled="columns.indexOf(col) === 0"
                  @click="$emit('reorder-status', col.status, 'up')"
                >
                  <span class="material-icons" style="font-size:16px">arrow_upward</span>
                </button>
                <button
                  class="icon-btn"
                  title="Move down"
                  :style="{ opacity: columns.indexOf(col) === columns.length - 1 ? 0.3 : 1, cursor: columns.indexOf(col) === columns.length - 1 ? 'not-allowed' : 'pointer' }"
                  :disabled="columns.indexOf(col) === columns.length - 1"
                  @click="$emit('reorder-status', col.status, 'down')"
                >
                  <span class="material-icons" style="font-size:16px">arrow_downward</span>
                </button>
                <button class="icon-btn" title="Edit" @click="startStatusEdit(col)">
                  <span class="material-icons" style="font-size:16px">edit</span>
                </button>
                <button class="icon-btn" title="Delete" style="color:var(--accent2)" @click="$emit('delete-status', col.status)">
                  <span class="material-icons" style="font-size:16px">delete</span>
                </button>
              </div>
            </div>
          </template>
        </div>

        <div v-if="!columns.length" class="text-center py-12" style="color:var(--muted)">
          <span class="material-icons" style="font-size:40px;display:block;margin-bottom:8px">view_kanban</span>
          <p class="text-sm">No statuses yet</p>
        </div>
      </div>

      <div v-if="activeTab === 'workspaces' && (currentUser.access === 'admin' || canManageSelectedWorkspace)" class="p-6 flex flex-col gap-4">
        <div class="flex items-center justify-between">
          <p class="text-xs font-mono" style="color:var(--muted)">WORKSPACES</p>
          <button class="btn-primary text-xs px-3 py-1.5" @click="$emit('create-workspace', { name: `Workspace ${workspaces.length + 1}`, memberIds: [] })">Quick Create</button>
        </div>

        <select class="field text-sm" :value="currentWorkspaceId" @change="selectedWorkspaceId = $event.target.value">
          <option v-for="w in workspaces" :key="w.id" :value="w.id">{{ w.name }}</option>
        </select>

        <div v-if="selectedWorkspace" class="member-row flex flex-col gap-3">
          <input class="field text-sm" v-model="workspaceName" placeholder="Workspace name" />
          <button class="btn-primary text-xs px-4 py-2" @click="$emit('rename-workspace', { id: selectedWorkspace.id, name: workspaceName })">Save Name</button>
        </div>

        <div v-if="selectedWorkspace" class="member-row flex flex-col gap-2">
          <div class="text-xs font-mono" style="color:var(--muted)">MEMBERS</div>
          <div v-for="m in membersInSelectedWorkspace" :key="m.id" class="flex items-center justify-between text-sm">
            <span>{{ m.name }}</span>
            <button v-if="m.id !== selectedWorkspace.ownerId" class="icon-btn" @click="$emit('remove-workspace-member', { workspaceId: selectedWorkspace.id, memberId: m.id })">
              <span class="material-icons" style="font-size:16px">person_remove</span>
            </button>
          </div>
          <select class="field text-sm mt-2" v-model="memberToAdd">
            <option value="">Add member...</option>
            <option v-for="m in availableMembersToAdd" :key="m.id" :value="m.id">{{ m.name }}</option>
          </select>
          <button class="btn-ghost text-xs px-3 py-1.5" :disabled="!memberToAdd" @click="emitAddMember">Add Member</button>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'

const props = defineProps({
  open:         Boolean,
  members:      Array,
  columns:      Array,
  tasks:        Array,
  memberColors: Array,
  currentUser:  Object,
  isDark:       Boolean,
  workspaces:   Array,
  currentWorkspaceId: String,
  workspaceMembers: Array,
})

const emit = defineEmits(['close', 'open-add-member', 'update-member', 'delete-member', 'update-status', 'set-done-status', 'add-status', 'delete-status', 'reorder-status', 'toggle-theme', 'create-workspace', 'rename-workspace', 'add-workspace-member', 'remove-workspace-member'])

const activeTab        = ref('members')
const editingId        = ref(null)
const editingStatusKey = ref(null)
const revealPwId       = ref(null)
const showEditPw       = ref(false)
const showAddStatus    = ref(false)
const selectedWorkspaceId = ref('')
const workspaceName = ref('')
const memberToAdd = ref('')

// user password change state
const newPassword     = ref('')
const confirmPassword = ref('')
const showNewPw       = ref(false)
const showConfirmPw   = ref(false)
const pwError         = ref('')

const editForm       = reactive({ name: '', role: '', email: '', password: '', color: '', access: 'user' })
const statusEditForm = reactive({ label: '', dot: '' })
const newStatusForm  = reactive({ label: '', dot: '#47ff8a' })

function savePassword() {
  pwError.value = ''
  if (!newPassword.value) { pwError.value = 'Please enter a new password.'; return }
  if (newPassword.value !== confirmPassword.value) { pwError.value = 'Passwords do not match.'; return }
  emit('update-member', {
    id:       props.currentUser.id,
    name:     props.currentUser.name,
    role:     props.currentUser.role,
    email:    props.currentUser.email,
    password: newPassword.value,
    color:    props.currentUser.color,
    access:   props.currentUser.access,
  })
  newPassword.value     = ''
  confirmPassword.value = ''
}

function slugify(label) {
  return label.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')
}

function submitAddStatus() {
  if (!newStatusForm.label.trim()) return
  emit('add-status', { label: newStatusForm.label.trim(), dot: newStatusForm.dot })
  Object.assign(newStatusForm, { label: '', dot: '#47ff8a' })
  showAddStatus.value = false
}

const taskCountByStatus = computed(() => {
  const counts = {}
  for (const t of props.tasks) counts[t.status] = (counts[t.status] ?? 0) + 1
  return counts
})

const selectedWorkspace = computed(() =>
  props.workspaces.find(w => w.id === (selectedWorkspaceId.value || props.currentWorkspaceId))
)
const canManageSelectedWorkspace = computed(() =>
  props.currentUser?.access === 'admin' || selectedWorkspace.value?.ownerId === props.currentUser?.id
)
const membersInSelectedWorkspace = computed(() => {
  if (!selectedWorkspace.value) return []
  const ids = new Set(props.workspaceMembers.filter(wm => wm.workspace_id === selectedWorkspace.value.id).map(wm => wm.member_id))
  return props.members.filter(m => ids.has(m.id))
})
const availableMembersToAdd = computed(() => {
  const existing = new Set(membersInSelectedWorkspace.value.map(m => m.id))
  return props.members.filter(m => !existing.has(m.id))
})
const hasOwnedWorkspace = computed(() =>
  props.workspaces.some(w => w.ownerId === props.currentUser?.id)
)
const showTabNav = computed(() =>
  props.currentUser?.access === 'admin' || hasOwnedWorkspace.value
)
const showUserPasswordView = computed(() =>
  props.currentUser?.access === 'user' && !showTabNav.value
)

function emitAddMember() {
  if (!selectedWorkspace.value || !memberToAdd.value) return
  emit('add-workspace-member', { workspaceId: selectedWorkspace.value.id, memberId: memberToAdd.value })
  memberToAdd.value = ''
}

function initials(name) {
  return (name || '?').split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase()
}

function startEdit(m) {
  editingId.value = m.id
  showEditPw.value = false
  Object.assign(editForm, {
    name:     m.name,
    role:     m.role,
    email:    m.email ?? '',
    password: '',
    color:    m.color,
    access:   m.access ?? 'user',
  })
}

function cancelEdit() {
  editingId.value = null
  showEditPw.value = false
}

function saveEdit(id) {
  emit('update-member', { id, ...editForm })
  editingId.value = null
  showEditPw.value = false
}

function startStatusEdit(col) {
  editingStatusKey.value = col.status
  Object.assign(statusEditForm, { label: col.label, dot: col.dot })
}

function saveStatusEdit(status) {
  emit('update-status', { status, label: statusEditForm.label, dot: statusEditForm.dot })
  editingStatusKey.value = null
}

watch(() => props.currentWorkspaceId, (id) => {
  selectedWorkspaceId.value = id
}, { immediate: true })

watch(selectedWorkspace, (w) => {
  workspaceName.value = w?.name ?? ''
}, { immediate: true })

watch(showTabNav, (show) => {
  if (!show) return
  if (activeTab.value === 'members' || activeTab.value === 'statuses') {
    if (props.currentUser?.access !== 'admin') activeTab.value = 'workspaces'
  }
}, { immediate: true })
</script>

<style scoped>
.member-row {
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 14px 16px;
  transition: border-color 0.15s;
}
.member-row:hover { border-color: var(--muted); }

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

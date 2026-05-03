<template>
  <AppHeader :clock="clock" @open-modal="openModal" />
  <ToastContainer :toasts="toasts" @remove="removeToast" />
  <StatsBar :tasks="tasks" :members="members" @open-modal="openModal" />
  <TabBar
    v-model:currentTab="currentTab"
    v-model:filterMember="filterMember"
    v-model:filterPriority="filterPriority"
    :members="members"
    :pending-count="pendingReminders.length"
  />

  <main class="p-6">
    <BoardView v-if="currentTab === 'board'"
      :columns="columns"
      :filtered-tasks="filteredTasks"
      :members="members"
      :reminders="reminders"
      :drag-over="dragOver"
      v-model:dragOver="dragOver"
      v-model:dragTaskId="dragTaskId"
      @drop="onDrop"
      @open-detail="openDetail"
      @toggle-done="toggleDone"
    />
    <ListView v-if="currentTab === 'list'"
      :tasks="filteredTasks"
      :members="members"
      @open-detail="openDetail"
      @toggle-done="toggleDone"
      @delete-task="deleteTask"
    />
    <RemindersView v-if="currentTab === 'reminders'"
      :reminders="reminders"
      :tasks="tasks"
      :members="members"
      @open-modal="openModal"
      @delete-reminder="deleteReminder"
    />
  </main>

  <AddTaskModal
    :open="modals.add"
    :form="form"
    :members="members"
    :shaking="shaking"
    @close="modals.add = false"
    @submit="addTask"
  />
  <AddReminderModal
    :open="modals.reminder"
    :form="remForm"
    :tasks="tasks"
    :members="members"
    @close="modals.reminder = false"
    @submit="addReminder"
  />
  <TaskDetailModal
    :open="modals.detail"
    :task="detailTask"
    :members="members"
    @close="modals.detail = false"
    @toggle-done="toggleDone"
    @delete-task="deleteTask"
  />
  <AddMemberModal
    :open="modals.member"
    :form="memberForm"
    :colors="memberColors"
    @close="modals.member = false"
    @submit="addMember"
  />
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { uid } from './utils.js'
import AppHeader       from './components/AppHeader.vue'
import ToastContainer  from './components/ToastContainer.vue'
import StatsBar        from './components/StatsBar.vue'
import TabBar          from './components/TabBar.vue'
import BoardView       from './components/BoardView.vue'
import ListView        from './components/ListView.vue'
import RemindersView   from './components/RemindersView.vue'
import AddTaskModal    from './components/AddTaskModal.vue'
import AddReminderModal from './components/AddReminderModal.vue'
import TaskDetailModal from './components/TaskDetailModal.vue'
import AddMemberModal  from './components/AddMemberModal.vue'

// ── state ─────────────────────────────────────────────────────────────────────
const clock          = ref('--:--:--')
const currentTab     = ref('board')
const filterMember   = ref('')
const filterPriority = ref('')
const dragTaskId     = ref(null)
const dragOver       = ref(null)
const detailTask     = ref(null)

const members = ref([
  { id: 'm1', name: 'Alex Kim',   role: 'Developer', color: '#e8ff47' },
  { id: 'm2', name: 'Mara Singh', role: 'Designer',  color: '#47c5ff' },
  { id: 'm3', name: 'Jordan Lee', role: 'PM',        color: '#ff9e47' },
])

const tasks     = ref([])
const reminders = ref([])
const toasts    = ref([])

const modals     = reactive({ add: false, reminder: false, detail: false, member: false })
const form       = reactive({ title: '', desc: '', assigneeId: '', priority: 'medium', due: '', status: 'todo', reminderDt: '' })
const remForm    = reactive({ title: '', taskId: '', datetime: '', assigneeId: 'team' })
const memberForm = reactive({ name: '', role: '', color: '#e8ff47' })
const memberColors = ['#e8ff47', '#ff4747', '#47c5ff', '#b47aff', '#ff9e47', '#47ffd4']
const shaking    = reactive({ taskTitle: false, taskAssignee: false })

// ── computed ──────────────────────────────────────────────────────────────────
const filteredTasks = computed(() => tasks.value.filter(t =>
  (!filterMember.value   || t.assigneeId === filterMember.value) &&
  (!filterPriority.value || t.priority   === filterPriority.value)
))

const pendingReminders = computed(() => reminders.value.filter(r => !r.fired))

const columns = [
  { status: 'todo',     label: 'Todo',        dot: '#666',            badgeClass: 'badge-gray'   },
  { status: 'progress', label: 'In Progress',  dot: 'var(--accent)',   badgeClass: 'badge-yellow' },
  { status: 'review',   label: 'Review',       dot: 'var(--accent3)',  badgeClass: 'badge-blue'   },
  { status: 'done',     label: 'Done',         dot: '#3a3a3a',         badgeClass: 'badge-gray'   },
]

// ── actions ───────────────────────────────────────────────────────────────────
function openModal(type) { modals[type] = true }

function openDetail(task) {
  detailTask.value = task
  modals.detail = true
}

function addTask() {
  if (!form.title.trim())  { triggerShake('taskTitle');    return }
  if (!form.assigneeId)    { triggerShake('taskAssignee'); return }

  const task = {
    id: uid(), title: form.title.trim(), desc: form.desc.trim(),
    assigneeId: form.assigneeId, priority: form.priority,
    due: form.due, status: form.status, done: false,
    createdAt: new Date().toISOString(),
  }
  tasks.value.push(task)

  if (form.reminderDt) {
    reminders.value.push({ id: uid(), title: `Task: ${task.title}`, taskId: task.id,
      datetime: form.reminderDt, assigneeId: form.assigneeId, fired: false })
  }

  modals.add = false
  Object.assign(form, { title: '', desc: '', assigneeId: '', priority: 'medium', due: '', status: 'todo', reminderDt: '' })
  showToast('Task Created', task.title, 'yellow')
}

function toggleDone(id) {
  const t = tasks.value.find(t => t.id === id)
  if (t) { t.done = !t.done; if (t.done) t.status = 'done' }
  if (detailTask.value?.id === id) detailTask.value = { ...t }
}

function deleteTask(id) {
  tasks.value     = tasks.value.filter(t => t.id !== id)
  reminders.value = reminders.value.filter(r => r.taskId !== id)
}

function addReminder() {
  if (!remForm.title.trim() || !remForm.datetime) return
  reminders.value.push({ id: uid(), ...remForm, fired: false })
  modals.reminder = false
  const title = remForm.title
  Object.assign(remForm, { title: '', taskId: '', datetime: '', assigneeId: 'team' })
  showToast('Reminder Set', title, 'yellow')
}

function deleteReminder(id) {
  reminders.value = reminders.value.filter(r => r.id !== id)
}

function addMember() {
  if (!memberForm.name.trim()) return
  members.value.push({ id: uid(), name: memberForm.name.trim(), role: memberForm.role.trim() || 'Team Member', color: memberForm.color })
  modals.member = false
  showToast('Member Added', `${memberForm.name} joined the team`, 'blue')
  Object.assign(memberForm, { name: '', role: '', color: '#e8ff47' })
}

function onDrop(status) {
  if (!dragTaskId.value) return
  const t = tasks.value.find(t => t.id === dragTaskId.value)
  if (t) { t.status = status; t.done = status === 'done' }
  dragTaskId.value = null
  dragOver.value   = null
}

// ── toast ─────────────────────────────────────────────────────────────────────
function showToast(title, msg, type = 'yellow', duration = 4000) {
  const colors = { yellow: 'var(--accent)', blue: 'var(--accent3)', red: 'var(--accent2)' }
  const id = uid()
  toasts.value.push({ id, title, msg, color: colors[type] || colors.yellow, fading: false })
  setTimeout(() => {
    const t = toasts.value.find(t => t.id === id)
    if (t) t.fading = true
    setTimeout(() => removeToast(id), 300)
  }, duration)
}

function removeToast(id) {
  toasts.value = toasts.value.filter(t => t.id !== id)
}

function triggerShake(key) {
  shaking[key] = true
  setTimeout(() => { shaking[key] = false }, 400)
}

// ── clock + reminder checker ──────────────────────────────────────────────────
let clockInterval, reminderInterval

onMounted(() => {
  clockInterval = setInterval(() => {
    clock.value = new Date().toLocaleTimeString('en-US', { hour12: false })
  }, 1000)
  clock.value = new Date().toLocaleTimeString('en-US', { hour12: false })

  reminderInterval = setInterval(() => {
    const now = new Date()
    reminders.value.forEach(r => {
      if (!r.fired && new Date(r.datetime) <= now) {
        r.fired = true
        showToast('Reminder', r.title, 'yellow', 8000)
      }
    })
  }, 15000)

  tasks.value = [
    { id: uid(), title: 'Design new landing page',   desc: 'Redesign the hero section with new brand colors', assigneeId: 'm2', priority: 'high',   due: '2026-05-06', status: 'progress', done: false, createdAt: new Date().toISOString() },
    { id: uid(), title: 'Fix auth bug in login flow', desc: 'Users getting logged out after 5 minutes',        assigneeId: 'm1', priority: 'high',   due: '2026-05-04', status: 'todo',     done: false, createdAt: new Date().toISOString() },
    { id: uid(), title: 'Write Q2 product roadmap',   desc: '',                                                assigneeId: 'm3', priority: 'medium', due: '2026-05-10', status: 'review',   done: false, createdAt: new Date().toISOString() },
    { id: uid(), title: 'Update README documentation',desc: '',                                                assigneeId: 'm1', priority: 'low',    due: '2026-05-15', status: 'todo',     done: false, createdAt: new Date().toISOString() },
    { id: uid(), title: 'Deploy v1.4.0 to production', desc: 'Release notes already written',                 assigneeId: 'm3', priority: 'medium', due: '2026-04-28', status: 'done',     done: true,  createdAt: new Date().toISOString() },
  ]
  reminders.value = [
    { id: uid(), title: 'Team standup at 9am', taskId: '', datetime: new Date(Date.now() + 60000).toISOString().slice(0, 16), assigneeId: 'team', fired: false },
  ]
})

onUnmounted(() => {
  clearInterval(clockInterval)
  clearInterval(reminderInterval)
})
</script>

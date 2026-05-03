<template>
  <AppHeader :clock="clock" @open-modal="openModal" @open-settings="showSettings = true" />
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
    <div v-if="loading" class="flex items-center justify-center py-24">
      <span class="material-icons animate-spin" style="color:var(--muted);font-size:32px">refresh</span>
    </div>
    <template v-else>
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
        :columns="columns"
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
    </template>
  </main>

  <AddTaskModal
    :open="modals.add"
    :form="form"
    :members="members"
    :columns="columns"
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
    :columns="columns"
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
  <SettingsSidebar
    :open="showSettings"
    :members="members"
    :columns="columns"
    :tasks="tasks"
    :member-colors="memberColors"
    @close="showSettings = false"
    @open-add-member="openModal('member')"
    @update-member="updateMember"
    @delete-member="deleteMember"
    @update-status="updateColumn"
    @add-status="addStatus"
    @delete-status="deleteStatus"
  />
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { uid, labelToKey } from './utils.js'
import { supabase } from './lib/supabase.js'
import AppHeader        from './components/AppHeader.vue'
import ToastContainer   from './components/ToastContainer.vue'
import StatsBar         from './components/StatsBar.vue'
import TabBar           from './components/TabBar.vue'
import BoardView        from './components/BoardView.vue'
import ListView         from './components/ListView.vue'
import RemindersView    from './components/RemindersView.vue'
import AddTaskModal     from './components/AddTaskModal.vue'
import AddReminderModal from './components/AddReminderModal.vue'
import TaskDetailModal  from './components/TaskDetailModal.vue'
import AddMemberModal   from './components/AddMemberModal.vue'
import SettingsSidebar  from './components/SettingsSidebar.vue'

// ── state ─────────────────────────────────────────────────────────────────────
const clock          = ref('--:--:--')
const currentTab     = ref('board')
const filterMember   = ref('')
const filterPriority = ref('')
const dragTaskId     = ref(null)
const dragOver       = ref(null)
const detailTask     = ref(null)
const loading        = ref(true)
const showSettings   = ref(false)

const members   = ref([])
const tasks     = ref([])
const reminders = ref([])
const toasts    = ref([])

const modals     = reactive({ add: false, reminder: false, detail: false, member: false })
const form       = reactive({ title: '', desc: '', assigneeId: '', priority: 'medium', due: '', status: 'todo', reminderDt: '' })
const remForm    = reactive({ title: '', taskId: '', datetime: '', assigneeId: 'team' })
const memberForm = reactive({ name: '', role: '', email: '', password: '', access: 'user', color: '#e8ff47' })
const memberColors = ['#e8ff47', '#ff4747', '#47c5ff', '#b47aff', '#ff9e47', '#47ffd4']
const shaking    = reactive({ taskTitle: false, taskAssignee: false })

// ── mappers ───────────────────────────────────────────────────────────────────
function mapTask(row) {
  return {
    id:         row.id,
    title:      row.title,
    desc:       row.description,
    assigneeId: row.assignee_id,
    priority:   row.priority,
    due:        row.due,
    status:     row.status,
    done:       row.done,
    createdAt:  row.created_at,
  }
}

function mapReminder(row) {
  return {
    id:         row.id,
    title:      row.title,
    taskId:     row.task_id,
    datetime:   row.datetime,
    assigneeId: row.assignee_id,
    fired:      row.fired,
  }
}

function mapMember(row) {
  return {
    id:       row.id,
    name:     row.name,
    role:     row.role,
    color:    row.color,
    access:   row.access ?? 'user',
    email:    row.email ?? '',
    password: row.password ?? '',
  }
}

// ── computed ──────────────────────────────────────────────────────────────────
const filteredTasks = computed(() => tasks.value.filter(t =>
  (!filterMember.value   || t.assigneeId === filterMember.value) &&
  (!filterPriority.value || t.priority   === filterPriority.value)
))

const pendingReminders = computed(() => reminders.value.filter(r => !r.fired))

const columns = ref([])

// ── mappers ───────────────────────────────────────────────────────────────────
function mapStatus(row) {
  return { id: row.id, status: row.key, label: row.label, dot: row.dot, sortOrder: row.sort_order }
}

// ── data fetching ─────────────────────────────────────────────────────────────
async function fetchAll() {
  loading.value = true
  const [mRes, tRes, rRes, sRes] = await Promise.all([
    supabase.from('members').select('*').order('created_at'),
    supabase.from('tasks').select('*').order('created_at'),
    supabase.from('reminders').select('*').order('created_at'),
    supabase.from('task_statuses').select('*').order('sort_order'),
  ])
  if (mRes.error || tRes.error || rRes.error || sRes.error) {
    showToast('Load Error', 'Could not fetch data from Supabase', 'red')
  } else {
    members.value   = mRes.data.map(mapMember)
    tasks.value     = tRes.data.map(mapTask)
    reminders.value = rRes.data.map(mapReminder)
    columns.value   = sRes.data.map(mapStatus)
    form.status     = columns.value[0]?.status ?? 'todo'
  }
  loading.value = false
}

// ── actions ───────────────────────────────────────────────────────────────────
function openModal(type) { modals[type] = true }

function openDetail(task) {
  detailTask.value = task
  modals.detail = true
}

async function addTask() {
  if (!form.title.trim())  { triggerShake('taskTitle');    return }
  if (!form.assigneeId)    { triggerShake('taskAssignee'); return }

  const { data, error } = await supabase.from('tasks').insert({
    title:       form.title.trim(),
    description: form.desc.trim(),
    assignee_id: form.assigneeId,
    priority:    form.priority,
    due:         form.due || null,
    status:      form.status,
    done:        false,
  }).select().single()

  if (error) { showToast('Error', 'Could not create task', 'red'); return }

  const task = mapTask(data)
  tasks.value.push(task)

  if (form.reminderDt) {
    const { data: rData, error: rErr } = await supabase.from('reminders').insert({
      title:       `Task: ${task.title}`,
      task_id:     task.id,
      datetime:    form.reminderDt,
      assignee_id: form.assigneeId,
      fired:       false,
    }).select().single()
    if (!rErr) reminders.value.push(mapReminder(rData))
  }

  modals.add = false
  Object.assign(form, { title: '', desc: '', assigneeId: '', priority: 'medium', due: '', status: columns.value[0]?.status ?? '', reminderDt: '' })
  showToast('Task Created', task.title, 'yellow')
}

async function toggleDone(id) {
  const t = tasks.value.find(t => t.id === id)
  if (!t) return
  const doneKey   = columns.value.at(-1)?.status ?? 'done'
  const firstKey  = columns.value[0]?.status ?? 'todo'
  const newDone   = !t.done
  const newStatus = newDone ? doneKey : t.status === doneKey ? firstKey : t.status
  t.done   = newDone
  t.status = newStatus
  if (detailTask.value?.id === id) detailTask.value = { ...t }

  const { error } = await supabase.from('tasks')
    .update({ done: newDone, status: newStatus })
    .eq('id', id)
  if (error) showToast('Error', 'Could not update task', 'red')
}

async function deleteTask(id) {
  tasks.value     = tasks.value.filter(t => t.id !== id)
  reminders.value = reminders.value.filter(r => r.taskId !== id)
  modals.detail   = false

  const { error } = await supabase.from('tasks').delete().eq('id', id)
  if (error) showToast('Error', 'Could not delete task', 'red')
}

async function addReminder() {
  if (!remForm.title.trim() || !remForm.datetime) return

  const { data, error } = await supabase.from('reminders').insert({
    title:       remForm.title.trim(),
    task_id:     remForm.taskId || null,
    datetime:    remForm.datetime,
    assignee_id: remForm.assigneeId,
    fired:       false,
  }).select().single()

  if (error) { showToast('Error', 'Could not create reminder', 'red'); return }

  reminders.value.push(mapReminder(data))
  modals.reminder = false
  const title = remForm.title
  Object.assign(remForm, { title: '', taskId: '', datetime: '', assigneeId: 'team' })
  showToast('Reminder Set', title, 'yellow')
}

async function deleteReminder(id) {
  reminders.value = reminders.value.filter(r => r.id !== id)
  const { error } = await supabase.from('reminders').delete().eq('id', id)
  if (error) showToast('Error', 'Could not delete reminder', 'red')
}

async function addMember() {
  if (!memberForm.name.trim()) return

  const payload = {
    name:   memberForm.name.trim(),
    role:   memberForm.role.trim() || 'Team Member',
    color:  memberForm.color,
    access: memberForm.access,
    email:  memberForm.email.trim() || null,
    password: memberForm.password || null,
  }

  const { data, error } = await supabase.from('members').insert(payload).select().single()

  if (error) { showToast('Error', 'Could not add member', 'red'); return }

  members.value.push(mapMember(data))
  modals.member = false
  showToast('Member Added', `${data.name} joined the team`, 'blue')
  Object.assign(memberForm, { name: '', role: '', email: '', password: '', access: 'user', color: '#e8ff47' })
}

async function updateMember({ id, name, role, email, password, color, access }) {
  const m = members.value.find(m => m.id === id)
  if (!m) return
  const patch = { name, role, color, access, email: email.trim() || null }
  if (password) patch.password = password
  Object.assign(m, patch)
  const { error } = await supabase.from('members').update(patch).eq('id', id)
  if (error) showToast('Error', 'Could not update member', 'red')
  else showToast('Member Updated', name, 'blue')
}

async function deleteMember(id) {
  const m = members.value.find(m => m.id === id)
  members.value = members.value.filter(m => m.id !== id)
  const { error } = await supabase.from('members').delete().eq('id', id)
  if (error) showToast('Error', 'Could not delete member', 'red')
  else showToast('Member Removed', m?.name ?? '', 'yellow')
}

async function updateColumn({ status, label, dot }) {
  const col = columns.value.find(c => c.status === status)
  if (!col) return
  col.label = label
  col.dot   = dot
  const { error } = await supabase.from('task_statuses').update({ label, dot }).eq('key', status)
  if (error) showToast('Error', 'Could not update status', 'red')
}

async function addStatus({ label, dot }) {
  const key = labelToKey(label)
  if (!key) return
  if (columns.value.some(c => c.status === key)) {
    showToast('Error', `Status key "${key}" already exists`, 'red'); return
  }
  const sortOrder = columns.value.length
  const { data, error } = await supabase.from('task_statuses')
    .insert({ key, label, dot, sort_order: sortOrder })
    .select().single()
  if (error) { showToast('Error', 'Could not add status', 'red'); return }
  columns.value.push(mapStatus(data))
  showToast('Status Added', label, 'yellow')
}

async function deleteStatus(status) {
  const inUse = tasks.value.some(t => t.status === status)
  if (inUse) {
    showToast('Error', 'Cannot delete — tasks exist with this status', 'red'); return
  }
  columns.value = columns.value.filter(c => c.status !== status)
  const { error } = await supabase.from('task_statuses').delete().eq('key', status)
  if (error) showToast('Error', 'Could not delete status', 'red')
  else showToast('Status Removed', status, 'yellow')
}

async function onDrop(status) {
  if (!dragTaskId.value) return
  const t = tasks.value.find(t => t.id === dragTaskId.value)
  if (!t) return
  const done = status === 'done'
  t.status = status
  t.done   = done
  dragTaskId.value = null
  dragOver.value   = null

  const { error } = await supabase.from('tasks')
    .update({ status, done })
    .eq('id', t.id)
  if (error) showToast('Error', 'Could not move task', 'red')
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

onMounted(async () => {
  clockInterval = setInterval(() => {
    clock.value = new Date().toLocaleTimeString('en-US', { hour12: false })
  }, 1000)
  clock.value = new Date().toLocaleTimeString('en-US', { hour12: false })

  await fetchAll()

  reminderInterval = setInterval(async () => {
    const now = new Date()
    for (const r of reminders.value) {
      if (!r.fired && new Date(r.datetime) <= now) {
        r.fired = true
        showToast('Reminder', r.title, 'yellow', 8000)
        await supabase.from('reminders').update({ fired: true }).eq('id', r.id)
      }
    }
  }, 15000)
})

onUnmounted(() => {
  clearInterval(clockInterval)
  clearInterval(reminderInterval)
})
</script>

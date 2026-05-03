<template>
  <!-- Login screen -->
  <LoginView
    v-if="!currentUser"
    :error="loginError"
    :loading="loginLoading"
    @login="login"
  />

  <!-- App -->
  <template v-else>
    <AppHeader
      :clock="clock"
      :current-user="currentUser"
      :unread-count="unreadCount"
      @open-modal="openModal"
      @open-settings="showSettings = true"
      @open-notifications="showNotifications = !showNotifications"
      @logout="logout"
    />
    <ToastContainer :toasts="toasts" @remove="removeToast" />
    <StatsBar :tasks="tasks" :members="members" @open-modal="openModal" />
    <TabBar
      v-model:currentTab="currentTab"
      v-model:filterMember="filterMember"
      v-model:filterPriority="filterPriority"
      :members="members"
      :pending-count="pendingReminders.length"
      :current-user="currentUser"
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
          :current-user="currentUser"
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
          :current-user="currentUser"
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
        <ActivityLogView v-if="currentTab === 'activity'" />
      </template>
    </main>

    <AddTaskModal
      :open="modals.add"
      :form="form"
      :members="members"
      :columns="columns"
      :shaking="shaking"
      :current-user="currentUser"
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
      :current-user="currentUser"
      @close="modals.detail = false"
      @toggle-done="toggleDone"
      @delete-task="deleteTask"
      @edit-task="editTask"
      @comment-added="onCommentAdded"
    />
    <AddMemberModal
      v-if="currentUser.access === 'admin'"
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
      :current-user="currentUser"
      :is-dark="isDark"
      @close="showSettings = false"
      @open-add-member="openModal('member')"
      @update-member="updateMember"
      @delete-member="deleteMember"
      @toggle-theme="toggleTheme"
      @update-status="updateColumn"
      @add-status="addStatus"
      @delete-status="deleteStatus"
      @reorder-status="reorderColumn"
    />
    <NotificationPanel
      :open="showNotifications"
      :notifications="notifications"
      @close="showNotifications = false"
      @mark-all-read="markAllNotificationsRead"
      @accept="n => n.type === 'task_reopen_request' ? acceptReopenRequest(n) : acceptAssignment(n)"
      @decline="n => n.type === 'task_reopen_request' ? declineReopenRequest(n) : declineAssignment(n)"
    />
  </template>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { uid, labelToKey } from './utils.js'
import { supabase } from './lib/supabase.js'
import LoginView        from './components/LoginView.vue'
import AppHeader        from './components/AppHeader.vue'
import ToastContainer   from './components/ToastContainer.vue'
import StatsBar         from './components/StatsBar.vue'
import TabBar           from './components/TabBar.vue'
import BoardView        from './components/BoardView.vue'
import ListView         from './components/ListView.vue'
import RemindersView    from './components/RemindersView.vue'
import ActivityLogView  from './components/ActivityLogView.vue'
import AddTaskModal     from './components/AddTaskModal.vue'
import AddReminderModal from './components/AddReminderModal.vue'
import TaskDetailModal  from './components/TaskDetailModal.vue'
import AddMemberModal   from './components/AddMemberModal.vue'
import SettingsSidebar  from './components/SettingsSidebar.vue'
import NotificationPanel from './components/NotificationPanel.vue'

// ── auth ──────────────────────────────────────────────────────────────────────
const currentUser  = ref(null)
const loginError   = ref('')
const loginLoading = ref(false)

async function login({ email, password }) {
  loginError.value   = ''
  loginLoading.value = true
  const { data, error } = await supabase
    .from('members')
    .select('*')
    .eq('email', email)
    .eq('password', password)
    .single()
  loginLoading.value = false
  if (error || !data) {
    loginError.value = 'Incorrect email or password.'
    return
  }
  currentUser.value = mapMember(data)
  localStorage.setItem('squad_user', JSON.stringify(currentUser.value))
  startApp()
}

function logout() {
  currentUser.value    = null
  loginError.value     = ''
  showNotifications.value = false
  localStorage.removeItem('squad_user')
  stopApp()
  members.value       = []
  tasks.value         = []
  reminders.value     = []
  columns.value       = []
  notifications.value = []
  loading.value       = true
}

// ── state ─────────────────────────────────────────────────────────────────────
const clock             = ref('--:--:--')
const currentTab        = ref('board')
const filterMember      = ref('')
const filterPriority    = ref('')
const dragTaskId        = ref(null)
const dragOver          = ref(null)
const detailTask        = ref(null)
const loading           = ref(true)
const showSettings      = ref(false)
const showNotifications = ref(false)
const isDark            = ref(localStorage.getItem('squad_theme') !== 'light')

const members       = ref([])
const tasks         = ref([])
const reminders     = ref([])
const notifications = ref([])
const toasts        = ref([])

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
    confirmed:  row.confirmed ?? true,
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

function mapStatus(row) {
  return { id: row.id, status: row.key, label: row.label, dot: row.dot, sortOrder: row.sort_order }
}

function mapNotification(row) {
  return {
    id:        row.id,
    memberId:  row.member_id,
    senderId:  row.sender_id,
    type:      row.type,
    message:   row.message,
    taskId:    row.task_id,
    read:      row.read,
    createdAt: row.created_at,
  }
}

// ── computed ──────────────────────────────────────────────────────────────────
const filteredTasks = computed(() => tasks.value.filter(t =>
  (!filterMember.value   || t.assigneeId === filterMember.value) &&
  (!filterPriority.value || t.priority   === filterPriority.value)
))

const pendingReminders = computed(() => reminders.value.filter(r => !r.fired))
const unreadCount      = computed(() => notifications.value.filter(n => !n.read).length)

const columns = ref([])

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
  await fetchNotifications()
}

async function fetchTasks() {
  const { data } = await supabase.from('tasks').select('*').order('created_at')
  if (data) tasks.value = data.map(mapTask)
}

async function fetchNotifications() {
  if (!currentUser.value) return
  const { data } = await supabase
    .from('notifications')
    .select('*')
    .eq('member_id', currentUser.value.id)
    .order('created_at', { ascending: false })
    .limit(50)
  if (data) notifications.value = data.map(mapNotification)
}

async function notifyAdmins(type, message, taskId) {
  const adminIds = members.value
    .filter(m => m.access === 'admin' && m.id !== currentUser.value.id)
    .map(m => m.id)
  if (!adminIds.length) return
  await supabase.from('notifications').insert(
    adminIds.map(id => ({
      member_id: id,
      sender_id: currentUser.value.id,
      type,
      message,
      task_id: taskId ?? null,
    }))
  )
}

// ── app lifecycle ─────────────────────────────────────────────────────────────
let clockInterval, reminderInterval, taskChannel, notifChannel

function startRealtimeSync() {
  taskChannel = supabase
    .channel('db-tasks')
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'tasks' }, ({ new: row }) => {
      if (!tasks.value.find(t => t.id === row.id)) tasks.value.push(mapTask(row))
    })
    .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'tasks' }, ({ new: row }) => {
      const idx = tasks.value.findIndex(t => t.id === row.id)
      if (idx !== -1) {
        tasks.value[idx] = mapTask(row)
        if (detailTask.value?.id === row.id) detailTask.value = mapTask(row)
      }
    })
    .on('postgres_changes', { event: 'DELETE', schema: 'public', table: 'tasks' }, ({ old: row }) => {
      tasks.value = tasks.value.filter(t => t.id !== row.id)
    })
    .subscribe((status, err) => {
      if (err) console.error('[tasks channel]', err)
      else console.log('[tasks channel]', status)
    })

  notifChannel = supabase
    .channel('db-notifications')
    .on('postgres_changes', {
      event: 'INSERT', schema: 'public', table: 'notifications',
      filter: `member_id=eq.${currentUser.value.id}`,
    }, ({ new: row }) => {
      if (!notifications.value.find(n => n.id === row.id)) {
        notifications.value.unshift(mapNotification(row))
        if (notifications.value.length > 50) notifications.value = notifications.value.slice(0, 50)
      }
    })
    .on('postgres_changes', {
      event: 'UPDATE', schema: 'public', table: 'notifications',
      filter: `member_id=eq.${currentUser.value.id}`,
    }, ({ new: row }) => {
      const idx = notifications.value.findIndex(n => n.id === row.id)
      if (idx !== -1) notifications.value[idx] = mapNotification(row)
    })
    .on('postgres_changes', { event: 'DELETE', schema: 'public', table: 'notifications' }, ({ old: row }) => {
      if (row.id) notifications.value = notifications.value.filter(n => n.id !== row.id)
    })
    .subscribe((status, err) => {
      if (err) console.error('[notifications channel]', err)
      else console.log('[notifications channel]', status)
    })
}

function stopRealtimeSync() {
  if (taskChannel) { supabase.removeChannel(taskChannel); taskChannel = null }
  if (notifChannel) { supabase.removeChannel(notifChannel); notifChannel = null }
}

function startApp() {
  clockInterval = setInterval(() => {
    clock.value = new Date().toLocaleTimeString('en-US', { hour12: false })
  }, 1000)
  clock.value = new Date().toLocaleTimeString('en-US', { hour12: false })

  fetchAll().then(() => {
    startRealtimeSync()
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
}

function stopApp() {
  clearInterval(clockInterval)
  clearInterval(reminderInterval)
  clockInterval = null
  reminderInterval = null
  stopRealtimeSync()
}

function applyTheme(dark) {
  document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light')
}

function toggleTheme() {
  isDark.value = !isDark.value
  applyTheme(isDark.value)
  localStorage.setItem('squad_theme', isDark.value ? 'dark' : 'light')
}

onMounted(() => {
  applyTheme(isDark.value)
  clock.value = new Date().toLocaleTimeString('en-US', { hour12: false })
  const saved = localStorage.getItem('squad_user')
  if (saved) {
    currentUser.value = JSON.parse(saved)
    startApp()
  }
})

onUnmounted(() => stopApp())

// ── actions ───────────────────────────────────────────────────────────────────
function openModal(type) { modals[type] = true }

function openDetail(task) {
  detailTask.value = task
  modals.detail = true
}

async function logActivity(action, entityType, entityId, message) {
  await supabase.from('activity_logs').insert({
    actor_id:    currentUser.value?.id ?? null,
    action,
    entity_type: entityType,
    entity_id:   String(entityId),
    message,
  })
}

async function addTask() {
  if (!form.title.trim())  { triggerShake('taskTitle');    return }
  if (!form.assigneeId)    { triggerShake('taskAssignee'); return }

  const isCrossAssignment = currentUser.value.access === 'user' &&
                            form.assigneeId !== currentUser.value.id
  const confirmed = !isCrossAssignment

  const { data, error } = await supabase.from('tasks').insert({
    title:       form.title.trim(),
    description: form.desc.trim(),
    assignee_id: form.assigneeId,
    priority:    form.priority,
    due:         form.due || null,
    status:      form.status,
    done:        false,
    confirmed,
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

  if (isCrossAssignment) {
    await supabase.from('notifications').insert({
      member_id: form.assigneeId,
      sender_id: currentUser.value.id,
      type:      'task_assignment_request',
      message:   `${currentUser.value.name} wants to assign you a task: "${task.title}"`,
      task_id:   task.id,
    })
    showToast('Task Sent', 'Waiting for assignee to confirm', 'yellow')
  } else {
    if (form.assigneeId !== currentUser.value.id) {
      await supabase.from('notifications').insert({
        member_id: form.assigneeId,
        sender_id: currentUser.value.id,
        type:      'task_assigned',
        message:   `${currentUser.value.name} assigned you a task: "${task.title}"`,
        task_id:   task.id,
      })
    }
    showToast('Task Created', task.title, 'yellow')
  }

  logActivity('task_created', 'task', task.id, `${currentUser.value.name} created task: "${task.title}"`)

  if (currentUser.value.access !== 'admin' && task.assigneeId) {
    const assigneeName = members.value.find(m => m.id === task.assigneeId)?.name ?? 'someone'
    await notifyAdmins(
      'task_assigned',
      `${currentUser.value.name} assigned a task to ${assigneeName}: "${task.title}"`,
      task.id,
    )
  }

  modals.add = false
  Object.assign(form, { title: '', desc: '', assigneeId: '', priority: 'medium', due: '', status: columns.value[0]?.status ?? '', reminderDt: '' })
}

async function editTask({ id, title, desc, priority, due, status }) {
  const t = tasks.value.find(t => t.id === id)
  if (!t) return
  if (currentUser.value.access !== 'admin' && t.assigneeId !== currentUser.value.id) {
    showToast('Permission Denied', 'You can only edit tasks assigned to you', 'red')
    return
  }
  Object.assign(t, { title, desc, priority, due, status })
  if (detailTask.value?.id === id) detailTask.value = { ...t }
  const { error } = await supabase.from('tasks').update({
    title,
    description: desc,
    priority,
    due:    due || null,
    status,
  }).eq('id', id)
  if (error) showToast('Error', 'Could not update task', 'red')
  else {
    showToast('Task Updated', title, 'yellow')
    logActivity('task_updated', 'task', id, `${currentUser.value.name} updated task: "${title}"`)
  }
}

async function onCommentAdded({ taskId, taskTitle }) {
  logActivity('task_commented', 'task', taskId, `${currentUser.value.name} commented on: "${taskTitle}"`)
  if (currentUser.value.access !== 'admin') {
    await notifyAdmins('task_commented', `${currentUser.value.name} commented on: "${taskTitle}"`, taskId)
  }
}

async function toggleDone(id) {
  const t = tasks.value.find(t => t.id === id)
  if (!t) return

  const isAdmin   = currentUser.value.access === 'admin'
  const isOwnTask = t.assigneeId === currentUser.value.id

  if (!isAdmin && !isOwnTask) {
    if (!t.done) {
      showToast('Permission Denied', 'You can only mark your own tasks as done', 'red')
      return
    }
    // User requesting to reopen another user's task → send approval request
    const assignee = members.value.find(m => m.id === t.assigneeId)
    await supabase.from('notifications').insert({
      member_id: t.assigneeId,
      sender_id: currentUser.value.id,
      type:      'task_reopen_request',
      message:   `${currentUser.value.name} wants to reopen your task: "${t.title}"`,
      task_id:   t.id,
    })
    showToast('Request Sent', `Reopen request sent to ${assignee?.name ?? 'assignee'}`, 'yellow')
    return
  }

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
  else {
    logActivity('task_status_changed', 'task', id,
      `${currentUser.value.name} marked "${t.title}" as ${newDone ? 'done' : 'reopened'}`)
    // Admin acting on someone else's task → notify the assignee
    if (isAdmin && t.assigneeId && t.assigneeId !== currentUser.value.id) {
      const action = newDone ? 'marked your task as done' : 'reopened your task'
      await supabase.from('notifications').insert({
        member_id: t.assigneeId,
        sender_id: currentUser.value.id,
        type:      newDone ? 'task_marked_done' : 'task_reopened',
        message:   `${currentUser.value.name} ${action}: "${t.title}"`,
        task_id:   t.id,
      })
    }
  }
}

async function deleteTask(id) {
  const t = tasks.value.find(t => t.id === id)
  tasks.value     = tasks.value.filter(t => t.id !== id)
  reminders.value = reminders.value.filter(r => r.taskId !== id)
  modals.detail   = false
  const { error } = await supabase.from('tasks').delete().eq('id', id)
  if (error) showToast('Error', 'Could not delete task', 'red')
  else logActivity('task_deleted', 'task', id, `${currentUser.value.name} deleted task: "${t?.title ?? id}"`)
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
  logActivity('reminder_created', 'reminder', data.id, `${currentUser.value.name} set reminder: "${title}"`)
}

async function deleteReminder(id) {
  reminders.value = reminders.value.filter(r => r.id !== id)
  const { error } = await supabase.from('reminders').delete().eq('id', id)
  if (error) showToast('Error', 'Could not delete reminder', 'red')
}

async function addMember() {
  if (!memberForm.name.trim()) return

  const payload = {
    name:     memberForm.name.trim(),
    role:     memberForm.role.trim() || 'Team Member',
    color:    memberForm.color,
    access:   memberForm.access,
    email:    memberForm.email.trim() || null,
    password: memberForm.password || null,
  }

  const { data, error } = await supabase.from('members').insert(payload).select().single()
  if (error) { showToast('Error', 'Could not add member', 'red'); return }

  members.value.push(mapMember(data))
  modals.member = false
  showToast('Member Added', `${data.name} joined the team`, 'blue')
  Object.assign(memberForm, { name: '', role: '', email: '', password: '', access: 'user', color: '#e8ff47' })
  logActivity('member_added', 'member', data.id, `${currentUser.value.name} added member: ${data.name}`)
}

async function updateMember({ id, name, role, email, password, color, access }) {
  const m = members.value.find(m => m.id === id)
  if (!m) return
  const patch = { name, role, color, access, email: email.trim() || null }
  if (password) patch.password = password
  Object.assign(m, patch)
  if (currentUser.value?.id === id) Object.assign(currentUser.value, patch)
  const { error } = await supabase.from('members').update(patch).eq('id', id)
  if (error) showToast('Error', 'Could not update member', 'red')
  else showToast('Member Updated', name, 'blue')
}

async function deleteMember(id) {
  const m = members.value.find(m => m.id === id)
  members.value = members.value.filter(m => m.id !== id)
  const { error } = await supabase.from('members').delete().eq('id', id)
  if (error) showToast('Error', 'Could not delete member', 'red')
  else {
    showToast('Member Removed', m?.name ?? '', 'yellow')
    logActivity('member_deleted', 'member', id, `${currentUser.value.name} removed member: ${m?.name ?? id}`)
  }
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

async function reorderColumn(status, direction) {
  const idx = columns.value.findIndex(c => c.status === status)
  if (idx === -1) return
  const targetIdx = direction === 'up' ? idx - 1 : idx + 1
  if (targetIdx < 0 || targetIdx >= columns.value.length) return

  [columns.value[idx], columns.value[targetIdx]] = [columns.value[targetIdx], columns.value[idx]]

  for (let i = 0; i < columns.value.length; i++) {
    const { error } = await supabase.from('task_statuses').update({ sort_order: i }).eq('key', columns.value[i].status)
    if (error) {
      showToast('Error', 'Could not reorder statuses', 'red')
      return
    }
    columns.value[i].sortOrder = i
  }
  showToast('Reordered', `${columns.value[targetIdx].label} moved`, 'yellow')
}

async function onDrop(status) {
  if (!dragTaskId.value) return
  const t = tasks.value.find(t => t.id === dragTaskId.value)
  if (!t) return
  if (currentUser.value.access !== 'admin' && t.assigneeId !== currentUser.value.id) {
    showToast('Permission Denied', 'You can only move tasks assigned to you', 'red')
    dragTaskId.value = null
    dragOver.value   = null
    return
  }
  const isDone = status === columns.value.at(-1)?.status
  t.status = status
  t.done   = isDone
  dragTaskId.value = null
  dragOver.value   = null

  const { error } = await supabase.from('tasks')
    .update({ status, done: isDone })
    .eq('id', t.id)
  if (error) showToast('Error', 'Could not move task', 'red')
  else {
    const colLabel = columns.value.find(c => c.status === status)?.label ?? status
    logActivity('task_status_changed', 'task', t.id,
      `${currentUser.value.name} moved "${t.title}" to ${colLabel}`)
    if (currentUser.value.access !== 'admin') {
      await notifyAdmins(
        'task_status_changed',
        `${currentUser.value.name} moved "${t.title}" to ${colLabel}`,
        t.id,
      )
    }
  }
}

// ── notifications actions ─────────────────────────────────────────────────────
async function markAllNotificationsRead() {
  const unreadIds = notifications.value.filter(n => !n.read).map(n => n.id)
  if (!unreadIds.length) return
  notifications.value.forEach(n => { n.read = true })
  await supabase.from('notifications').update({ read: true }).in('id', unreadIds)
}

async function acceptAssignment(notif) {
  const t = tasks.value.find(t => t.id === notif.taskId)
  if (t) t.confirmed = true
  await supabase.from('tasks').update({ confirmed: true }).eq('id', notif.taskId)
  notifications.value = notifications.value.filter(n => n.id !== notif.id)
  await supabase.from('notifications').delete().eq('id', notif.id)

  if (notif.senderId) {
    const assigneeName = currentUser.value.name
    await supabase.from('notifications').insert({
      member_id: notif.senderId,
      sender_id: currentUser.value.id,
      type:      'task_confirmed',
      message:   `${assigneeName} accepted your task: "${t?.title ?? ''}"`,
      task_id:   notif.taskId,
    })
  }

  showToast('Task Accepted', t?.title ?? '', 'yellow')
  logActivity('task_confirmed', 'task', notif.taskId,
    `${currentUser.value.name} accepted task assignment: "${t?.title ?? ''}"`)
}

async function declineAssignment(notif) {
  const t = tasks.value.find(t => t.id === notif.taskId)
  tasks.value     = tasks.value.filter(t => t.id !== notif.taskId)
  reminders.value = reminders.value.filter(r => r.taskId !== notif.taskId)
  await supabase.from('tasks').delete().eq('id', notif.taskId)
  notifications.value = notifications.value.filter(n => n.id !== notif.id)
  await supabase.from('notifications').delete().eq('id', notif.id)

  if (notif.senderId) {
    await supabase.from('notifications').insert({
      member_id: notif.senderId,
      sender_id: currentUser.value.id,
      type:      'task_declined',
      message:   `${currentUser.value.name} declined your task: "${t?.title ?? ''}"`,
      task_id:   null,
    })
  }

  showToast('Task Declined', t?.title ?? '', 'red')
  logActivity('task_declined', 'task', notif.taskId ?? 'unknown',
    `${currentUser.value.name} declined task assignment: "${t?.title ?? ''}"`)
}

async function acceptReopenRequest(notif) {
  const t = tasks.value.find(t => t.id === notif.taskId)
  if (t) {
    const firstKey = columns.value[0]?.status ?? 'todo'
    const doneKey  = columns.value.at(-1)?.status ?? 'done'
    t.done   = false
    t.status = t.status === doneKey ? firstKey : t.status
    await supabase.from('tasks').update({ done: false, status: t.status }).eq('id', t.id)
    if (detailTask.value?.id === t.id) detailTask.value = { ...t }
  }
  notifications.value = notifications.value.filter(n => n.id !== notif.id)
  await supabase.from('notifications').delete().eq('id', notif.id)
  if (notif.senderId) {
    await supabase.from('notifications').insert({
      member_id: notif.senderId,
      sender_id: currentUser.value.id,
      type:      'task_reopen_accepted',
      message:   `${currentUser.value.name} accepted your reopen request for: "${t?.title ?? ''}"`,
      task_id:   notif.taskId,
    })
  }
  showToast('Reopen Accepted', t?.title ?? '', 'yellow')
  logActivity('task_status_changed', 'task', notif.taskId,
    `${currentUser.value.name} accepted reopen request for: "${t?.title ?? ''}"`)
}

async function declineReopenRequest(notif) {
  const t = tasks.value.find(t => t.id === notif.taskId)
  notifications.value = notifications.value.filter(n => n.id !== notif.id)
  await supabase.from('notifications').delete().eq('id', notif.id)
  if (notif.senderId) {
    await supabase.from('notifications').insert({
      member_id: notif.senderId,
      sender_id: currentUser.value.id,
      type:      'task_reopen_declined',
      message:   `${currentUser.value.name} declined your reopen request for: "${t?.title ?? ''}"`,
      task_id:   notif.taskId,
    })
  }
  showToast('Reopen Declined', t?.title ?? '', 'red')
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
</script>

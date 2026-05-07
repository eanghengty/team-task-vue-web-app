<template>
  <div class="modal-overlay" :class="{ open }" @click.self="closeModal">
    <div class="modal p-0 flex flex-col" style="max-height:88vh" v-if="task">

      <!-- Header -->
      <div class="p-5 flex-shrink-0" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <span class="font-display text-xl tracking-wider">TASK DETAIL</span>
            <span v-if="task.confirmed === false"
              class="badge text-xs" style="background:rgba(255,158,71,0.15);color:#ff9e47;border:1px solid rgba(255,158,71,0.3)">
              PENDING
            </span>
          </div>
          <div class="flex items-center gap-2">
            <button v-if="canEdit && !editMode" @click="startEdit"
              class="btn-ghost text-xs flex items-center gap-1 px-2 py-1.5">
              <span class="material-icons" style="font-size:14px">edit</span>Edit
            </button>
            <button @click="closeModal" style="color:var(--muted);display:flex;align-items:center">
              <span class="material-icons" style="font-size:20px">close</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Scrollable body -->
      <div class="flex-1 overflow-y-auto">

        <!-- ── VIEW MODE ───────────────────────────────────────── -->
        <div v-if="!editMode" class="p-5 flex flex-col gap-4">

          <!-- Title + desc -->
          <div>
            <div class="flex items-center gap-2 mb-1">
              <div class="w-2 h-2 rounded-full" :style="{ background: priorityDotColor(task.priority) }"></div>
              <span class="font-semibold text-base" :class="{ 'line-through': task.done }"
                :style="task.done ? 'color:var(--muted)' : ''">{{ task.title }}</span>
            </div>
            <p v-if="task.desc" class="text-sm mt-2" style="color:#aaa">{{ task.desc }}</p>
          </div>

          <!-- Info grid -->
          <div class="grid grid-cols-2 gap-3 text-sm">
            <div class="p-3 rounded-lg" style="background:var(--surface2)">
              <div class="text-xs font-mono mb-1" style="color:var(--muted)">ASSIGNED TO</div>
              <div class="flex items-center gap-2">
                <div class="avatar" :style="{ background: assignee?.color || '#444', color: '#000' }">
                  {{ assignee?.name?.slice(0, 2).toUpperCase() || '?' }}
                </div>
                <span>{{ assignee?.name || 'Unassigned' }}</span>
              </div>
            </div>
            <div class="p-3 rounded-lg" style="background:var(--surface2)">
              <div class="text-xs font-mono mb-1" style="color:var(--muted)">DUE DATE</div>
              <div :class="{ 'text-red-400': overdue }">{{ task.due || '—' }}</div>
              <div v-if="overdue" class="text-xs text-red-400">Overdue!</div>
            </div>
            <div class="p-3 rounded-lg" style="background:var(--surface2)">
              <div class="text-xs font-mono mb-1" style="color:var(--muted)">PRIORITY</div>
              <div class="flex items-center gap-2">
                <div class="w-2 h-2 rounded-full" :style="{ background: priorityDotColor(task.priority) }"></div>
                {{ task.priority }}
              </div>
            </div>
            <div class="p-3 rounded-lg" style="background:var(--surface2)">
              <div class="text-xs font-mono mb-1" style="color:var(--muted)">STATUS</div>
              <div>{{ statusLabel(task.status) }}</div>
            </div>
          </div>

          <!-- Pending warning -->
          <div v-if="task.confirmed === false"
            class="text-xs px-3 py-2.5 rounded-lg font-mono"
            style="background:rgba(255,158,71,0.08);color:#ff9e47;border:1px solid rgba(255,158,71,0.25)">
            <span class="material-icons" style="font-size:13px;vertical-align:-2px;margin-right:4px">schedule</span>
            Waiting for assignee to accept this task.
          </div>

          <!-- Action buttons -->
          <div v-if="task.confirmed !== false && canEdit" class="flex gap-2">
            <button class="btn-primary text-sm flex-1"
              @click="$emit('toggle-done', task.id); closeModal()">
              {{ task.done ? 'Reopen' : 'Mark Done' }}
            </button>
            <button v-if="canDelete" class="btn-ghost text-sm"
              style="color:var(--accent2);border-color:rgba(255,71,71,0.3)"
              @click="$emit('delete-task', task.id); closeModal()">
              Delete
            </button>
          </div>

          <!-- ── COMMENTS ──────────────────────────────────────── -->
          <div style="border-top:1px solid var(--border)" class="pt-4 flex flex-col gap-3">
            <div class="text-xs font-mono" style="color:var(--muted)">
              COMMENTS ({{ comments.length }})
            </div>

            <div v-if="commentsLoading" class="flex justify-center py-4">
              <span class="material-icons animate-spin" style="color:var(--muted);font-size:18px">refresh</span>
            </div>

            <div v-else class="flex flex-col gap-2">
              <div v-if="!comments.length" class="text-xs" style="color:var(--muted)">
                No comments yet. Add a progress update or note below.
              </div>
              <div v-for="c in comments" :key="c.id" class="rounded-lg p-3" style="background:var(--surface2)">
                <div class="flex items-center gap-2 mb-1.5">
                  <div class="avatar flex-shrink-0" style="width:20px;height:20px;font-size:8px"
                    :style="{ background: commentAuthor(c.member_id)?.color || '#444', color: '#0d0d0d' }">
                    {{ (commentAuthor(c.member_id)?.name || '?').slice(0, 2).toUpperCase() }}
                  </div>
                  <span class="text-xs font-medium">{{ commentAuthor(c.member_id)?.name || 'Unknown' }}</span>
                  <span class="text-xs font-mono ml-auto" style="color:var(--muted)">{{ fmtDate(c.created_at) }}</span>
                </div>
                <p class="text-sm" style="color:#ccc;line-height:1.5">{{ c.content }}</p>
              </div>
            </div>

            <!-- comment input -->
            <div class="flex gap-2">
              <input class="field text-sm flex-1" v-model="commentInput"
                placeholder="Add a comment, progress update, or obstacle…"
                @keyup.enter="submitComment" />
              <button class="btn-primary px-3" @click="submitComment" title="Send">
                <span class="material-icons" style="font-size:16px">send</span>
              </button>
            </div>
          </div>
        </div>

        <!-- ── EDIT MODE ───────────────────────────────────────── -->
        <div v-else class="p-5 flex flex-col gap-4">
          <div>
            <label class="text-xs font-mono mb-1.5 block" style="color:var(--muted)">TITLE</label>
            <input class="field" v-model="editForm.title" placeholder="Task title" />
          </div>
          <div>
            <label class="text-xs font-mono mb-1.5 block" style="color:var(--muted)">DESCRIPTION</label>
            <textarea class="field" v-model="editForm.desc" rows="3" placeholder="Description…"></textarea>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-xs font-mono mb-1.5 block" style="color:var(--muted)">PRIORITY</label>
              <select class="field text-sm" v-model="editForm.priority">
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
              </select>
            </div>
            <div>
              <label class="text-xs font-mono mb-1.5 block" style="color:var(--muted)">DUE DATE</label>
              <input class="field text-sm" type="date" v-model="editForm.due" />
            </div>
          </div>
          <div>
            <label class="text-xs font-mono mb-1.5 block" style="color:var(--muted)">STATUS</label>
            <select class="field text-sm" v-model="editForm.status">
              <option v-for="col in columns" :key="col.status" :value="col.status">{{ col.label }}</option>
            </select>
          </div>
          <div v-if="currentUser?.access === 'admin'">
            <label class="text-xs font-mono mb-1.5 block" style="color:var(--muted)">WORKSPACE</label>
            <select class="field text-sm" v-model="editForm.workspaceId">
              <option v-for="w in workspaces" :key="w.id" :value="w.id">{{ w.name }}</option>
            </select>
          </div>
          <div class="flex gap-2 pt-2">
            <button class="btn-primary text-sm flex-1" @click="saveEdit">Save Changes</button>
            <button class="btn-ghost text-sm" @click="editMode = false">Cancel</button>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'
import { priorityDotColor, isOverdue } from '../utils.js'
import { supabase } from '../lib/supabase.js'

const props = defineProps({
  open:        Boolean,
  task:        Object,
  members:     Array,
  columns:     Array,
  workspaces:  Array,
  currentUser: Object,
  workspaceId: String,
})
const emit = defineEmits(['close', 'toggle-done', 'delete-task', 'edit-task', 'comment-added'])

// ── permissions ───────────────────────────────────────────────────────────────
const canEdit = computed(() =>
  props.currentUser?.access === 'admin' ||
  props.task?.assigneeId === props.currentUser?.id
)
const canDelete = computed(() =>
  props.currentUser?.access === 'admin' ||
  props.task?.assigneeId === props.currentUser?.id
)

// ── view state ────────────────────────────────────────────────────────────────
const editMode = ref(false)
const editForm = reactive({ title: '', desc: '', priority: 'medium', due: '', status: '', workspaceId: '' })

const assignee    = computed(() => props.members.find(m => m.id === props.task?.assigneeId))
const overdue     = computed(() => props.task ? isOverdue(props.task) : false)
const statusLabel = (key) => props.columns?.find(c => c.status === key)?.label ?? key

function closeModal() {
  editMode.value = false
  emit('close')
}

function startEdit() {
  Object.assign(editForm, {
    title:    props.task.title,
    desc:     props.task.desc ?? '',
    priority: props.task.priority,
    due:      props.task.due ?? '',
    status:   props.task.status,
    workspaceId: props.task.workspaceId ?? props.workspaceId ?? '',
  })
  editMode.value = true
}

function saveEdit() {
  emit('edit-task', { id: props.task.id, ...editForm })
  editMode.value = false
}

watch(() => props.open, (val) => { if (!val) editMode.value = false })

// ── comments ──────────────────────────────────────────────────────────────────
const comments        = ref([])
const commentsLoading = ref(false)
const commentInput    = ref('')

const commentAuthor = (id) => props.members.find(m => m.id === id)

async function fetchComments() {
  if (!props.task?.id) return
  commentsLoading.value = true
  const { data } = await supabase
    .from('task_comments')
    .select('*')
    .eq('workspace_id', props.workspaceId)
    .eq('task_id', props.task.id)
    .order('created_at')
  comments.value = data ?? []
  commentsLoading.value = false
}

async function submitComment() {
  const content = commentInput.value.trim()
  if (!content) return
  const { data, error } = await supabase.from('task_comments').insert({
    workspace_id: props.workspaceId,
    task_id:   props.task.id,
    member_id: props.currentUser?.id ?? null,
    content,
  }).select().single()
  if (!error && data) {
    comments.value.push(data)
    commentInput.value = ''
    emit('comment-added', { taskId: props.task.id, taskTitle: props.task.title })
  }
}

function fmtDate(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  return d.toLocaleDateString('en-AU', { day: '2-digit', month: 'short' }) + ' ' +
         d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })
}

watch(() => props.task?.id, fetchComments)
watch(() => props.open, (val) => { if (val) fetchComments() })
</script>

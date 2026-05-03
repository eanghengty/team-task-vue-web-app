<template>
  <!-- HEADER -->
  <header class="header px-6 py-3 flex items-center justify-between sticky top-0 z-[100]"
    style="border-bottom:1px solid var(--border);background:rgba(13,13,13,0.9);backdrop-filter:blur(12px)">
    <div class="flex items-center gap-4">
      <span class="font-display text-3xl tracking-widest" style="color:var(--accent)">SQUAD</span>
      <span class="badge badge-gray font-mono text-xs">v2.0</span>
    </div>
    <div class="flex items-center gap-3">
      <div class="font-mono text-sm" style="color:var(--muted)">{{ clock }}</div>
      <div class="w-px h-5" style="background:var(--border)"></div>
      <button @click="openModal('add')" class="btn-primary flex items-center gap-2">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M7 1v12M1 7h12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
        New Task
      </button>
      <button @click="openModal('reminder')" class="btn-ghost flex items-center gap-2">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        Reminders
      </button>
    </div>
  </header>

  <!-- TOAST CONTAINER -->
  <div class="toast-container">
    <div v-for="toast in toasts" :key="toast.id"
      class="toast" :class="{ 'fade-out': toast.fading }"
      :style="{ borderColor: toast.color }">
      <div class="w-2 h-2 rounded-full flex-shrink-0 mt-1" :style="{ background: toast.color }"></div>
      <div class="flex-1 min-w-0">
        <div class="text-sm font-semibold">{{ toast.title }}</div>
        <div class="text-xs mt-0.5 truncate" style="color:var(--muted)">{{ toast.msg }}</div>
      </div>
      <button @click="removeToast(toast.id)" style="color:var(--muted);font-size:14px;flex-shrink:0">✕</button>
    </div>
  </div>

  <!-- STATS BAR -->
  <div class="px-6 py-4 flex gap-3 overflow-x-auto" style="border-bottom:1px solid var(--border)">
    <div class="stat-card flex items-center gap-3 flex-shrink-0">
      <span class="font-display text-3xl" style="color:var(--accent)">{{ tasks.length }}</span>
      <div><div class="text-xs font-mono" style="color:var(--muted)">TOTAL</div><div class="text-xs" style="color:var(--muted)">tasks</div></div>
    </div>
    <div class="stat-card flex items-center gap-3 flex-shrink-0">
      <span class="font-display text-3xl" style="color:#47c5ff">{{ openCount }}</span>
      <div><div class="text-xs font-mono" style="color:var(--muted)">OPEN</div><div class="text-xs" style="color:var(--muted)">pending</div></div>
    </div>
    <div class="stat-card flex items-center gap-3 flex-shrink-0">
      <span class="font-display text-3xl" style="color:#ff4747">{{ overdueCount }}</span>
      <div><div class="text-xs font-mono" style="color:var(--muted)">OVERDUE</div><div class="text-xs" style="color:var(--muted)">tasks</div></div>
    </div>
    <div class="stat-card flex-1 flex-shrink-0 min-w-48">
      <div class="flex justify-between items-center mb-2">
        <span class="text-xs font-mono" style="color:var(--muted)">PROGRESS</span>
        <span class="text-xs font-mono" style="color:var(--accent)">{{ progressPct }}%</span>
      </div>
      <div class="progress-bar"><div class="progress-fill" :style="{ width: progressPct + '%' }"></div></div>
    </div>
    <!-- Members card -->
    <div class="stat-card flex items-center gap-2 flex-shrink-0 cursor-pointer"
      @click="openModal('member')" style="border-color:rgba(232,255,71,0.2)">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <div>
        <div class="text-xs font-mono" style="color:var(--muted)">MEMBERS</div>
        <div class="text-xs" style="color:var(--accent)">{{ members.length }} active</div>
      </div>
    </div>
  </div>

  <!-- TABS -->
  <div class="px-6 py-3 flex items-center gap-2" style="border-bottom:1px solid var(--border)">
    <button class="tab-btn" :class="{ active: currentTab === 'board' }" @click="currentTab = 'board'">Board</button>
    <button class="tab-btn" :class="{ active: currentTab === 'list' }" @click="currentTab = 'list'">List</button>
    <button class="tab-btn" :class="{ active: currentTab === 'reminders' }" @click="currentTab = 'reminders'">
      Reminders
      <span class="badge badge-yellow ml-1" style="font-size:10px;padding:1px 6px">{{ pendingReminders.length }}</span>
    </button>
    <div class="flex-1"></div>
    <div class="flex items-center gap-2">
      <span class="text-xs" style="color:var(--muted)">Filter:</span>
      <select class="field text-xs" style="width:auto;padding:5px 10px" v-model="filterMember">
        <option value="">All Members</option>
        <option v-for="m in members" :key="m.id" :value="m.id">{{ m.name }}</option>
      </select>
      <select class="field text-xs" style="width:auto;padding:5px 10px" v-model="filterPriority">
        <option value="">All Priority</option>
        <option value="high">High</option>
        <option value="medium">Medium</option>
        <option value="low">Low</option>
      </select>
    </div>
  </div>

  <!-- MAIN -->
  <main class="p-6">

    <!-- BOARD VIEW -->
    <div v-if="currentTab === 'board'" class="flex gap-4 overflow-x-auto pb-4">
      <div v-for="col in columns" :key="col.status"
        class="column"
        :class="{ 'drag-over': dragOver === col.status }"
        @dragover.prevent="dragOver = col.status"
        @dragleave="dragOver = null"
        @drop.prevent="onDrop(col.status)">
        <div class="column-header">
          <div class="w-2 h-2 rounded-full flex-shrink-0" :style="{ background: col.dot }"></div>
          <span class="text-sm font-semibold">{{ col.label }}</span>
          <span class="ml-auto badge" :class="col.badgeClass">{{ filteredByStatus(col.status).length }}</span>
        </div>
        <div class="p-3 flex flex-col gap-2">
          <div v-if="filteredByStatus(col.status).length === 0"
            class="text-center py-6 text-xs font-mono" style="color:var(--muted)">drop here</div>
          <div v-for="task in filteredByStatus(col.status)" :key="task.id"
            class="task-card fade-up"
            :class="['priority-' + task.priority, { done: task.done }]"
            draggable="true"
            @dragstart="dragTaskId = task.id"
            @dragend="dragOver = null"
            @click="openDetail(task)">
            <div class="flex items-start gap-2 mb-2">
              <div class="checkbox-custom mt-0.5" :class="{ checked: task.done }"
                @click.stop="toggleDone(task.id)">
                <svg v-if="task.done" width="10" height="8" viewBox="0 0 10 8" fill="none"><path d="M1 4l3 3 5-6" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
              </div>
              <div class="flex-1 min-w-0">
                <div class="task-title text-sm font-medium leading-snug">{{ task.title }}</div>
                <div v-if="task.desc" class="text-xs mt-1 truncate" style="color:var(--muted)">{{ task.desc }}</div>
              </div>
            </div>
            <div class="flex items-center justify-between mt-3">
              <div class="flex items-center gap-2">
                <template v-if="memberById(task.assigneeId)">
                  <div class="avatar" :style="{ background: memberById(task.assigneeId).color, color: '#000' }">
                    {{ memberById(task.assigneeId).name.slice(0,2).toUpperCase() }}
                  </div>
                </template>
                <span v-if="task.due" class="text-xs font-mono" :class="{ 'text-red-400': isOverdue(task) }" :style="isOverdue(task) ? '' : 'color:var(--muted)'">
                  {{ isOverdue(task) ? '⚠ ' : '' }}{{ task.due }}
                </span>
              </div>
              <div class="flex items-center gap-1">
                <svg v-if="hasActiveReminder(task.id)" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#e8ff47" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                <div class="rounded-full" :class="'bg-' + priorityColor(task.priority)" style="width:6px;height:6px"
                  :style="{ background: priorityDotColor(task.priority) }"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- LIST VIEW -->
    <div v-if="currentTab === 'list'">
      <div class="rounded-lg overflow-hidden" style="border:1px solid var(--border)">
        <table class="w-full text-sm">
          <thead>
            <tr style="background:var(--surface);border-bottom:1px solid var(--border)">
              <th v-for="h in ['DONE','TASK','ASSIGNED','DUE','PRIORITY','STATUS','ACTIONS']" :key="h"
                class="text-left p-3 font-mono text-xs" style="color:var(--muted)">{{ h }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredTasks.length === 0">
              <td colspan="7" class="text-center py-8 text-sm font-mono" style="color:var(--muted)">no tasks yet</td>
            </tr>
            <tr v-for="task in filteredTasks" :key="task.id"
              class="border-b cursor-pointer hover:opacity-80 transition-opacity"
              style="border-color:var(--border);background:var(--surface)"
              @click="openDetail(task)">
              <td class="p-3">
                <div class="checkbox-custom" :class="{ checked: task.done }" @click.stop="toggleDone(task.id)">
                  <svg v-if="task.done" width="10" height="8" viewBox="0 0 10 8" fill="none"><path d="M1 4l3 3 5-6" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
                </div>
              </td>
              <td class="p-3 text-sm" :class="{ 'line-through': task.done }" :style="task.done ? 'color:var(--muted)' : ''">{{ task.title }}</td>
              <td class="p-3">
                <div class="flex items-center gap-2">
                  <div v-if="memberById(task.assigneeId)" class="avatar" :style="{ background: memberById(task.assigneeId).color, color: '#000', width:'22px', height:'22px', fontSize:'9px' }">
                    {{ memberById(task.assigneeId).name.slice(0,2).toUpperCase() }}
                  </div>
                  <span class="text-sm">{{ memberById(task.assigneeId)?.name || '—' }}</span>
                </div>
              </td>
              <td class="p-3 text-sm font-mono" :class="{ 'text-red-400': isOverdue(task) }" :style="!isOverdue(task) ? 'color:var(--muted)' : ''">{{ task.due || '—' }}</td>
              <td class="p-3">
                <div class="flex items-center gap-2">
                  <div class="w-2 h-2 rounded-full" :style="{ background: priorityDotColor(task.priority) }"></div>
                  <span class="text-xs capitalize">{{ task.priority }}</span>
                </div>
              </td>
              <td class="p-3">
                <span class="badge" :class="statusBadgeClass(task.status)">{{ statusLabel(task.status) }}</span>
              </td>
              <td class="p-3">
                <button @click.stop="deleteTask(task.id)" class="text-xs font-mono hover:text-red-400 transition-colors" style="color:var(--muted)">del</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- REMINDERS VIEW -->
    <div v-if="currentTab === 'reminders'" class="max-w-2xl">
      <div class="flex items-center justify-between mb-4">
        <h2 class="font-display text-2xl tracking-wider">REMINDERS</h2>
        <button @click="openModal('reminder')" class="btn-primary text-xs">+ Add Reminder</button>
      </div>
      <div v-if="reminders.length === 0" class="text-center py-12">
        <div class="font-mono text-sm" style="color:var(--muted)">no reminders set</div>
      </div>
      <div v-else class="flex flex-col gap-3">
        <div v-for="r in reminders" :key="r.id" class="reminder-item fade-up" :class="{ 'opacity-50': r.fired }">
          <div class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center"
            :style="{ background: r.fired ? 'var(--surface)' : 'rgba(232,255,71,0.12)', border: '1px solid ' + (r.fired ? 'var(--border)' : 'rgba(232,255,71,0.3)') }">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" :stroke="r.fired ? 'var(--muted)' : 'var(--accent)'" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium" :class="{ 'line-through': r.fired }" :style="r.fired ? 'color:var(--muted)' : ''">{{ r.title }}</div>
            <div class="flex items-center gap-3 mt-1">
              <span class="text-xs font-mono" :class="{ 'text-red-400': isPastReminder(r) }" :style="!isPastReminder(r) ? 'color:var(--muted)' : ''">
                {{ new Date(r.datetime).toLocaleString() }}
              </span>
              <span v-if="linkedTask(r)" class="text-xs" style="color:var(--muted)">→ {{ linkedTask(r).title }}</span>
              <div v-if="reminderMember(r)" class="avatar" :style="{ background: reminderMember(r).color, color: '#000', width:'18px', height:'18px', fontSize:'8px' }">
                {{ reminderMember(r).name.slice(0,2).toUpperCase() }}
              </div>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <span v-if="r.fired" class="badge badge-gray text-xs">fired</span>
            <button @click="deleteReminder(r.id)" class="text-xs font-mono hover:text-red-400 transition-colors" style="color:var(--muted)">✕</button>
          </div>
        </div>
      </div>
    </div>

  </main>

  <!-- ADD TASK MODAL -->
  <div class="modal-overlay" :class="{ open: modals.add }" @click.self="modals.add = false">
    <div class="modal p-0">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-2xl tracking-wider">NEW TASK</span>
          <button @click="modals.add = false" style="color:var(--muted)" class="hover:text-white">
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M1 1l16 16M17 1L1 17" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
          </button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">TASK TITLE *</label>
          <input class="field" :class="{ 'shake': shaking.taskTitle }" v-model="form.title" placeholder="What needs to be done?" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">DESCRIPTION</label>
          <textarea class="field" v-model="form.desc" rows="2" placeholder="Add details..."></textarea>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-mono mb-2" style="color:var(--muted)">ASSIGN TO *</label>
            <select class="field" :class="{ 'shake': shaking.taskAssignee }" v-model="form.assigneeId">
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
              <option value="todo">Todo</option>
              <option value="progress">In Progress</option>
              <option value="review">Review</option>
              <option value="done">Done</option>
            </select>
          </div>
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">SET REMINDER</label>
          <input class="field" v-model="form.reminderDt" type="datetime-local" />
          <p class="text-xs mt-1" style="color:var(--muted)">Leave blank for no reminder</p>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary flex-1" @click="addTask">Create Task</button>
          <button class="btn-ghost" @click="modals.add = false">Cancel</button>
        </div>
      </div>
    </div>
  </div>

  <!-- ADD REMINDER MODAL -->
  <div class="modal-overlay" :class="{ open: modals.reminder }" @click.self="modals.reminder = false">
    <div class="modal p-0">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-2xl tracking-wider">NEW REMINDER</span>
          <button @click="modals.reminder = false" style="color:var(--muted)" class="hover:text-white">
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M1 1l16 16M17 1L1 17" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
          </button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">REMINDER TITLE *</label>
          <input class="field" v-model="remForm.title" placeholder="What should I remind you about?" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">LINKED TASK (optional)</label>
          <select class="field" v-model="remForm.taskId">
            <option value="">None</option>
            <option v-for="t in tasks" :key="t.id" :value="t.id">{{ t.title }}</option>
          </select>
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">REMIND AT *</label>
          <input class="field" v-model="remForm.datetime" type="datetime-local" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">NOTIFY</label>
          <select class="field" v-model="remForm.assigneeId">
            <option value="team">Whole Team</option>
            <option v-for="m in members" :key="m.id" :value="m.id">{{ m.name }}</option>
          </select>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary flex-1" @click="addReminder">Set Reminder</button>
          <button class="btn-ghost" @click="modals.reminder = false">Cancel</button>
        </div>
      </div>
    </div>
  </div>

  <!-- TASK DETAIL MODAL -->
  <div class="modal-overlay" :class="{ open: modals.detail }" @click.self="modals.detail = false">
    <div class="modal p-0" v-if="detailTask">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-xl tracking-wider">TASK DETAIL</span>
          <button @click="modals.detail = false" style="color:var(--muted)">✕</button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <div class="flex items-center gap-2 mb-1">
            <div class="w-2 h-2 rounded-full" :style="{ background: priorityDotColor(detailTask.priority) }"></div>
            <span class="font-semibold text-base" :class="{ 'line-through': detailTask.done }" :style="detailTask.done ? 'color:var(--muted)' : ''">{{ detailTask.title }}</span>
          </div>
          <p v-if="detailTask.desc" class="text-sm mt-2" style="color:#aaa">{{ detailTask.desc }}</p>
        </div>
        <div class="grid grid-cols-2 gap-3 text-sm">
          <div class="p-3 rounded-lg" style="background:var(--surface2)">
            <div class="text-xs font-mono mb-1" style="color:var(--muted)">ASSIGNED TO</div>
            <div class="flex items-center gap-2">
              <div class="avatar" :style="{ background: memberById(detailTask.assigneeId)?.color || '#444', color: '#000' }">
                {{ memberById(detailTask.assigneeId)?.name?.slice(0,2).toUpperCase() || '?' }}
              </div>
              <span>{{ memberById(detailTask.assigneeId)?.name || 'Unassigned' }}</span>
            </div>
          </div>
          <div class="p-3 rounded-lg" style="background:var(--surface2)">
            <div class="text-xs font-mono mb-1" style="color:var(--muted)">DUE DATE</div>
            <div :class="{ 'text-red-400': isOverdue(detailTask) }">{{ detailTask.due || '—' }}</div>
            <div v-if="isOverdue(detailTask)" class="text-xs text-red-400">Overdue!</div>
          </div>
          <div class="p-3 rounded-lg" style="background:var(--surface2)">
            <div class="text-xs font-mono mb-1" style="color:var(--muted)">PRIORITY</div>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 rounded-full" :style="{ background: priorityDotColor(detailTask.priority) }"></div>
              {{ detailTask.priority }}
            </div>
          </div>
          <div class="p-3 rounded-lg" style="background:var(--surface2)">
            <div class="text-xs font-mono mb-1" style="color:var(--muted)">STATUS</div>
            <div>{{ statusLabel(detailTask.status) }}</div>
          </div>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary text-sm flex-1" @click="toggleDone(detailTask.id); modals.detail = false">
            {{ detailTask.done ? 'Reopen' : 'Mark Done' }}
          </button>
          <button class="btn-ghost text-sm" style="color:var(--accent2);border-color:rgba(255,71,71,0.3)"
            @click="deleteTask(detailTask.id); modals.detail = false">Delete</button>
        </div>
      </div>
    </div>
  </div>

  <!-- ADD MEMBER MODAL -->
  <div class="modal-overlay" :class="{ open: modals.member }" @click.self="modals.member = false">
    <div class="modal p-0" style="max-width:400px">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-2xl tracking-wider">ADD MEMBER</span>
          <button @click="modals.member = false" style="color:var(--muted)">✕</button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">FULL NAME *</label>
          <input class="field" v-model="memberForm.name" placeholder="e.g. Alex Kim" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">ROLE</label>
          <input class="field" v-model="memberForm.role" placeholder="e.g. Designer" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">COLOR</label>
          <div class="flex gap-2">
            <div v-for="c in memberColors" :key="c"
              class="w-7 h-7 rounded-full cursor-pointer transition-all"
              :style="{ background: c, border: memberForm.color === c ? '2px solid white' : '2px solid transparent' }"
              @click="memberForm.color = c"></div>
          </div>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary flex-1" @click="addMember">Add Member</button>
          <button class="btn-ghost" @click="modals.member = false">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'

// ── helpers ──────────────────────────────────────────────────────────────────
const uid = () => '_' + Math.random().toString(36).substr(2, 9)

// ── state ────────────────────────────────────────────────────────────────────
const clock = ref('--:--:--')
const currentTab = ref('board')
const filterMember = ref('')
const filterPriority = ref('')
const dragTaskId = ref(null)
const dragOver = ref(null)
const detailTask = ref(null)

const members = ref([
  { id: 'm1', name: 'Alex Kim',    role: 'Developer', color: '#e8ff47' },
  { id: 'm2', name: 'Mara Singh',  role: 'Designer',  color: '#47c5ff' },
  { id: 'm3', name: 'Jordan Lee',  role: 'PM',        color: '#ff9e47' },
])

const tasks = ref([])
const reminders = ref([])
const toasts = ref([])

const modals = reactive({ add: false, reminder: false, detail: false, member: false })

const form = reactive({ title: '', desc: '', assigneeId: '', priority: 'medium', due: '', status: 'todo', reminderDt: '' })
const remForm = reactive({ title: '', taskId: '', datetime: '', assigneeId: 'team' })
const memberForm = reactive({ name: '', role: '', color: '#e8ff47' })
const memberColors = ['#e8ff47','#ff4747','#47c5ff','#b47aff','#ff9e47','#47ffd4']

const shaking = reactive({ taskTitle: false, taskAssignee: false })

// ── computed ─────────────────────────────────────────────────────────────────
const filteredTasks = computed(() => tasks.value.filter(t =>
  (!filterMember.value || t.assigneeId === filterMember.value) &&
  (!filterPriority.value || t.priority === filterPriority.value)
))

const filteredByStatus = (status) =>
  filteredTasks.value.filter(t => t.status === status)

const doneCount    = computed(() => tasks.value.filter(t => t.done || t.status === 'done').length)
const openCount    = computed(() => tasks.value.length - doneCount.value)
const overdueCount = computed(() => tasks.value.filter(t => isOverdue(t)).length)
const progressPct  = computed(() => tasks.value.length === 0 ? 0 : Math.round(doneCount.value / tasks.value.length * 100))
const pendingReminders = computed(() => reminders.value.filter(r => !r.fired))

const columns = [
  { status: 'todo',     label: 'Todo',        dot: '#666',             badgeClass: 'badge-gray' },
  { status: 'progress', label: 'In Progress',  dot: 'var(--accent)',   badgeClass: 'badge-yellow' },
  { status: 'review',   label: 'Review',       dot: 'var(--accent3)',  badgeClass: 'badge-blue' },
  { status: 'done',     label: 'Done',         dot: '#3a3a3a',         badgeClass: 'badge-gray' },
]

// ── helpers ───────────────────────────────────────────────────────────────────
const memberById    = (id) => members.value.find(m => m.id === id)
const isOverdue     = (t)  => t.due && !t.done && new Date(t.due) < new Date()
const hasActiveReminder = (id) => reminders.value.some(r => r.taskId === id && !r.fired)
const statusLabel   = (s) => ({ todo:'Todo', progress:'In Progress', review:'Review', done:'Done' }[s])
const statusBadgeClass = (s) => ({ todo:'badge-gray', progress:'badge-yellow', review:'badge-blue', done:'badge-gray' }[s])
const priorityDotColor = (p) => ({ high:'var(--accent2)', medium:'var(--accent)', low:'var(--accent3)' }[p])
const linkedTask    = (r) => r.taskId ? tasks.value.find(t => t.id === r.taskId) : null
const reminderMember = (r) => r.assigneeId && r.assigneeId !== 'team' ? memberById(r.assigneeId) : null
const isPastReminder = (r) => !r.fired && new Date(r.datetime) < new Date()

// ── actions ───────────────────────────────────────────────────────────────────
function openModal(type) {
  modals[type] = true
}

function openDetail(task) {
  detailTask.value = task
  modals.detail = true
}

function addTask() {
  if (!form.title.trim())    { triggerShake('taskTitle');    return }
  if (!form.assigneeId)      { triggerShake('taskAssignee'); return }

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
  Object.assign(form, { title:'', desc:'', assigneeId:'', priority:'medium', due:'', status:'todo', reminderDt:'' })
  showToast('✅ Task Created', task.title, 'yellow')
}

function toggleDone(id) {
  const t = tasks.value.find(t => t.id === id)
  if (t) { t.done = !t.done; if (t.done) t.status = 'done' }
  if (detailTask.value?.id === id) detailTask.value = { ...t }
}

function deleteTask(id) {
  tasks.value = tasks.value.filter(t => t.id !== id)
  reminders.value = reminders.value.filter(r => r.taskId !== id)
}

function addReminder() {
  if (!remForm.title.trim()) return
  if (!remForm.datetime)     return
  reminders.value.push({ id: uid(), ...remForm, fired: false })
  modals.reminder = false
  Object.assign(remForm, { title:'', taskId:'', datetime:'', assigneeId:'team' })
  showToast('⏰ Reminder Set', remForm.title || 'Reminder added', 'yellow')
}

function deleteReminder(id) {
  reminders.value = reminders.value.filter(r => r.id !== id)
}

function addMember() {
  if (!memberForm.name.trim()) return
  members.value.push({ id: uid(), name: memberForm.name.trim(), role: memberForm.role.trim() || 'Team Member', color: memberForm.color })
  modals.member = false
  showToast('🧑‍💼 Member Added', `${memberForm.name} joined the team`, 'blue')
  Object.assign(memberForm, { name:'', role:'', color:'#e8ff47' })
}

function onDrop(status) {
  if (!dragTaskId.value) return
  const t = tasks.value.find(t => t.id === dragTaskId.value)
  if (t) { t.status = status; t.done = status === 'done' }
  dragTaskId.value = null
  dragOver.value = null
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

// ── shake ──────────────────────────────────────────────────────────────────────
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
        showToast('⏰ Reminder', r.title, 'yellow', 8000)
      }
    })
  }, 15000)

  // seed
  const suid = uid
  tasks.value = [
    { id: suid(), title: 'Design new landing page', desc: 'Redesign the hero section with new brand colors', assigneeId: 'm2', priority: 'high', due: '2026-05-06', status: 'progress', done: false, createdAt: new Date().toISOString() },
    { id: suid(), title: 'Fix auth bug in login flow', desc: 'Users getting logged out after 5 minutes', assigneeId: 'm1', priority: 'high', due: '2026-05-04', status: 'todo', done: false, createdAt: new Date().toISOString() },
    { id: suid(), title: 'Write Q2 product roadmap', desc: '', assigneeId: 'm3', priority: 'medium', due: '2026-05-10', status: 'review', done: false, createdAt: new Date().toISOString() },
    { id: suid(), title: 'Update README documentation', desc: '', assigneeId: 'm1', priority: 'low', due: '2026-05-15', status: 'todo', done: false, createdAt: new Date().toISOString() },
    { id: suid(), title: 'Deploy v1.4.0 to production', desc: 'Release notes already written', assigneeId: 'm3', priority: 'medium', due: '2026-04-28', status: 'done', done: true, createdAt: new Date().toISOString() },
  ]
  reminders.value = [
    { id: suid(), title: 'Team standup at 9am', taskId: '', datetime: new Date(Date.now() + 60000).toISOString().slice(0,16), assigneeId: 'team', fired: false },
  ]
})

onUnmounted(() => {
  clearInterval(clockInterval)
  clearInterval(reminderInterval)
})
</script>

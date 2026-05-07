<template>
  <div
    class="fixed inset-0 z-[250]"
    :style="{ pointerEvents: open ? 'all' : 'none' }"
    @click="$emit('close')"
  />

  <div
    class="fixed z-[260] flex flex-col rounded-xl shadow-2xl transition-all duration-200"
    style="width:360px;max-height:520px;top:56px;right:16px;background:var(--surface);border:1px solid var(--border)"
    :style="{ opacity: open ? 1 : 0, transform: open ? 'translateY(0)' : 'translateY(-6px)', pointerEvents: open ? 'all' : 'none' }"
  >
    <!-- header -->
    <div class="flex items-center justify-between px-4 py-3 flex-shrink-0" style="border-bottom:1px solid var(--border)">
      <div class="flex items-center gap-2">
        <span class="material-icons" style="color:var(--accent);font-size:18px">notifications</span>
        <span class="font-display text-lg tracking-widest">NOTIFICATIONS</span>
        <span v-if="unread > 0" class="badge badge-yellow" style="font-size:10px;padding:1px 7px">{{ unread }}</span>
      </div>
      <button v-if="unread > 0" class="text-xs font-mono hover:opacity-80 transition-opacity"
        style="color:var(--muted)" @click.stop="$emit('mark-all-read')">
        Mark all read
      </button>
    </div>

    <!-- list -->
    <div class="flex-1 overflow-y-auto">
      <div v-if="!notifications.length" class="text-center py-10" style="color:var(--muted)">
        <span class="material-icons" style="font-size:36px;display:block;margin-bottom:8px">notifications_none</span>
        <p class="text-sm">No notifications</p>
      </div>

      <div v-for="n in notifications" :key="n.id"
        class="px-4 py-3 flex flex-col gap-2"
        :style="{ background: n.read ? 'transparent' : 'rgba(232,255,71,0.04)', borderBottom: '1px solid var(--border)' }">
        <div class="flex items-start gap-2">
          <span class="material-icons flex-shrink-0 mt-0.5" style="font-size:16px"
            :style="{ color: iconColor(n.type) }">{{ iconName(n.type) }}</span>
          <div class="flex-1 min-w-0">
            <p class="text-sm leading-snug">{{ n.message }}</p>
            <p class="text-xs font-mono mt-0.5" style="color:var(--muted)">{{ fmtDate(n.createdAt) }}</p>
          </div>
          <div v-if="!n.read" class="w-2 h-2 rounded-full flex-shrink-0 mt-1.5" style="background:var(--accent)"></div>
        </div>

        <!-- accept / decline for assignment and reopen requests -->
        <div v-if="n.type === 'task_assignment_request' || n.type === 'task_reopen_request'" class="flex gap-2">
          <button class="btn-primary text-xs px-3 py-1.5 flex-1" @click.stop="$emit('accept', n)">
            <span class="material-icons" style="font-size:13px;vertical-align:-2px;margin-right:3px">check</span>Accept
          </button>
          <button class="btn-ghost text-xs px-3 py-1.5"
            style="color:var(--accent2);border-color:rgba(255,71,71,0.3)"
            @click.stop="$emit('decline', n)">
            <span class="material-icons" style="font-size:13px;vertical-align:-2px;margin-right:3px">close</span>Decline
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  open:          Boolean,
  notifications: Array,
})
defineEmits(['close', 'mark-all-read', 'accept', 'decline'])

const unread = computed(() => props.notifications.filter(n => !n.read).length)

function iconName(type) {
  const map = {
    task_assigned:          'assignment_ind',
    task_assignment_request:'assignment_late',
    task_confirmed:         'check_circle',
    task_declined:          'cancel',
    task_commented:         'chat_bubble',
    task_status_changed:    'swap_horiz',
    task_reopen_request:    'refresh',
    task_reopen_accepted:   'check_circle',
    task_reopen_declined:   'cancel',
    task_marked_done:       'task_alt',
    task_reopened:          'replay',
    chat_message:           'chat',
  }
  return map[type] ?? 'info'
}

function iconColor(type) {
  if (type === 'task_assignment_request') return 'var(--accent)'
  if (type === 'task_reopen_request')     return 'var(--accent)'
  if (type === 'task_confirmed')          return '#47ffd4'
  if (type === 'task_reopen_accepted')    return '#47ffd4'
  if (type === 'task_declined')           return 'var(--accent2)'
  if (type === 'task_reopen_declined')    return 'var(--accent2)'
  if (type === 'task_commented')          return '#aaaaaa'
  if (type === 'task_status_changed')     return 'var(--accent3)'
  if (type === 'task_marked_done')        return 'var(--accent3)'
  if (type === 'task_reopened')           return 'var(--accent3)'
  if (type === 'chat_message')            return 'var(--accent3)'
  return 'var(--accent3)'
}

function fmtDate(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  return d.toLocaleDateString('en-AU', { day: '2-digit', month: 'short' }) + ' ' +
         d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })
}
</script>

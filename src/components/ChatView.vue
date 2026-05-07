<template>
  <section class="card p-0 overflow-hidden" style="min-height:65vh">
    <div class="px-5 py-3 flex items-center justify-between" style="border-bottom:1px solid var(--border)">
      <div>
        <h2 class="font-display tracking-wide text-xl" style="color:var(--accent)">Workspace Chat</h2>
        <p class="text-xs" style="color:var(--muted)">Messages are visible to all members in this workspace.</p>
      </div>
      <button
        v-if="isAdmin && messages.length"
        class="btn-ghost text-xs px-2 py-1"
        style="color:var(--accent2);border-color:rgba(255,71,71,0.35)"
        @click="confirmDeleteAll"
      >
        Delete All
      </button>
    </div>

    <div ref="listRef" class="px-4 py-4 space-y-3 overflow-y-auto" style="max-height:52vh">
      <div v-if="!messages?.length" class="text-sm py-8 text-center" style="color:var(--muted)">
        No messages yet. Start the conversation.
      </div>

      <article
        v-for="msg in messages"
        :key="msg.id"
        class="rounded-lg px-3 py-2"
        style="border:1px solid var(--border);background:var(--surface)"
      >
        <div class="flex items-center justify-between gap-3 mb-1">
          <div class="text-sm font-semibold" style="color:var(--text)">
            {{ memberName(msg.senderId) }}
          </div>
          <time class="font-mono text-[11px]" style="color:var(--muted)">
            {{ formatTime(msg.createdAt) }}
          </time>
        </div>

        <div
          v-if="replyContext(msg)"
          class="rounded px-2 py-1 mb-2 text-xs"
          style="border-left:3px solid var(--accent3);background:var(--surface-2);color:var(--muted)"
        >
          <span class="font-semibold" style="color:var(--text)">{{ replyContext(msg).name }}</span>
          <span class="mx-1">-</span>
          <span>{{ replyContext(msg).preview }}</span>
        </div>

        <p class="text-sm whitespace-pre-wrap break-words">{{ msg.content }}</p>
        <div class="mt-2 flex items-center gap-2">
          <button class="btn-ghost text-xs px-2 py-1" @click="setReplyTarget(msg)">Reply</button>
          <button
            v-if="isAdmin"
            class="btn-ghost text-xs px-2 py-1"
            style="color:var(--accent2);border-color:rgba(255,71,71,0.35)"
            @click="confirmDeleteMessage(msg.id)"
          >
            Delete
          </button>
        </div>
      </article>
    </div>

    <form class="px-4 py-3" style="border-top:1px solid var(--border)" @submit.prevent="submit">
      <div
        v-if="replyTarget"
        class="w-full mb-2 rounded px-2 py-1 text-xs"
        style="border-left:3px solid var(--accent3);background:var(--surface-2)"
      >
        <div class="flex items-center justify-between gap-2">
          <div class="truncate" style="color:var(--muted)">
            Replying to <span class="font-semibold" style="color:var(--text)">{{ memberName(replyTarget.senderId) }}</span>:
            "{{ compact(replyTarget.content) }}"
          </div>
          <button type="button" class="btn-ghost px-2 py-0.5" @click="clearReply">Cancel</button>
        </div>
      </div>

      <div class="flex items-end gap-2">
        <textarea
          v-model="draft"
          rows="2"
          maxlength="2000"
          class="field"
          placeholder="Type a message..."
          style="resize:none"
          @keydown.enter.exact.prevent="submit"
        />
        <button type="submit" class="btn-primary h-10 px-4" :disabled="!draft.trim()">Send</button>
      </div>
    </form>
  </section>
</template>

<script setup>
import { computed, nextTick, ref, watch } from 'vue'

const props = defineProps({
  messages: { type: Array, default: () => [] },
  members: { type: Array, default: () => [] },
  currentUser: { type: Object, default: null },
})

const emit = defineEmits(['send-message', 'mark-read', 'delete-message', 'delete-all-messages'])
const draft = ref('')
const listRef = ref(null)
const replyTarget = ref(null)
const isAdmin = computed(() => props.currentUser?.access === 'admin')

function memberName(senderId) {
  return props.members.find(m => m.id === senderId)?.name ?? 'Unknown Member'
}

function formatTime(value) {
  return new Date(value).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  })
}

async function scrollToBottom() {
  await nextTick()
  if (listRef.value) listRef.value.scrollTop = listRef.value.scrollHeight
}

async function submit() {
  const content = draft.value.trim()
  if (!content) return
  emit('send-message', { content, replyToMessageId: replyTarget.value?.id ?? null })
  draft.value = ''
  clearReply()
  await scrollToBottom()
}

function compact(text) {
  if (!text) return ''
  return text.length > 72 ? `${text.slice(0, 72)}...` : text
}

function setReplyTarget(msg) {
  replyTarget.value = msg
}

function clearReply() {
  replyTarget.value = null
}

function confirmDeleteMessage(messageId) {
  if (!isAdmin.value) return
  if (window.confirm('Delete this chat message?')) {
    emit('delete-message', messageId)
  }
}

function confirmDeleteAll() {
  if (!isAdmin.value) return
  if (window.confirm('Delete all chat messages in this workspace? This cannot be undone.')) {
    emit('delete-all-messages')
  }
}

function replyContext(msg) {
  if (!msg.replyToMessageId) return null
  const parent = props.messages.find(m => m.id === msg.replyToMessageId)
  if (!parent) return { name: 'Original message', preview: 'Message unavailable' }
  return {
    name: memberName(parent.senderId),
    preview: compact(parent.content),
  }
}

watch(
  () => props.messages.length,
  async () => {
    emit('mark-read')
    await scrollToBottom()
  },
  { immediate: true }
)
</script>

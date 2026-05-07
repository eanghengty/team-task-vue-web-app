<template>
  <section class="card p-0 overflow-hidden" style="min-height:65vh">
    <div class="px-5 py-3 flex items-center justify-between" style="border-bottom:1px solid var(--border)">
      <div>
        <h2 class="font-display tracking-wide text-xl" style="color:var(--accent)">Workspace Chat</h2>
        <p class="text-xs" style="color:var(--muted)">Messages are visible to all members in this workspace.</p>
      </div>
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
        <p class="text-sm whitespace-pre-wrap break-words">{{ msg.content }}</p>
      </article>
    </div>

    <form class="px-4 py-3 flex items-end gap-2" style="border-top:1px solid var(--border)" @submit.prevent="submit">
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
    </form>
  </section>
</template>

<script setup>
import { nextTick, ref, watch } from 'vue'

const props = defineProps({
  messages: { type: Array, default: () => [] },
  members: { type: Array, default: () => [] },
})

const emit = defineEmits(['send-message', 'mark-read'])
const draft = ref('')
const listRef = ref(null)

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
  emit('send-message', content)
  draft.value = ''
  await scrollToBottom()
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

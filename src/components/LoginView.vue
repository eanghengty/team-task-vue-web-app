<template>
  <div class="fixed inset-0 flex items-center justify-center" style="background:var(--bg)">
    <div style="width:380px">
      <!-- Logo -->
      <div class="text-center mb-8">
        <div class="font-display text-5xl tracking-widest mb-1" style="color:var(--accent)">SQUAD</div>
        <div class="text-xs font-mono" style="color:var(--muted)">TEAM TASK BOARD</div>
      </div>

      <!-- Card -->
      <div class="p-8 rounded-2xl flex flex-col gap-5" style="background:var(--surface);border:1px solid var(--border)">
        <div>
          <div class="font-display text-xl tracking-widest mb-1">SIGN IN</div>
          <div class="text-xs" style="color:var(--muted)">Enter your credentials to continue</div>
        </div>

        <div class="flex flex-col gap-3">
          <div>
            <label class="text-xs font-mono mb-1.5 block" style="color:var(--muted)">EMAIL</label>
            <input
              class="field w-full"
              type="email"
              v-model="email"
              placeholder="you@example.com"
              autocomplete="email"
              @keyup.enter="submit"
            />
          </div>
          <div>
            <label class="text-xs font-mono mb-1.5 block" style="color:var(--muted)">PASSWORD</label>
            <div class="relative">
              <input
                class="field w-full pr-10"
                :type="showPw ? 'text' : 'password'"
                v-model="password"
                placeholder="••••••••"
                autocomplete="current-password"
                @keyup.enter="submit"
              />
              <button
                type="button"
                class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center"
                style="color:var(--muted)"
                @click="showPw = !showPw"
              >
                <span class="material-icons" style="font-size:16px">{{ showPw ? 'visibility_off' : 'visibility' }}</span>
              </button>
            </div>
          </div>
        </div>

        <div v-if="error" class="text-xs px-3 py-2 rounded-lg font-mono" style="background:rgba(255,71,71,0.12);color:var(--accent2);border:1px solid rgba(255,71,71,0.25)">
          {{ error }}
        </div>

        <button
          class="btn-primary w-full flex items-center justify-center gap-2 py-2.5"
          :disabled="loading"
          @click="submit"
        >
          <span v-if="loading" class="material-icons animate-spin" style="font-size:16px">refresh</span>
          <span>{{ loading ? 'Signing in…' : 'Sign In' }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

defineProps({
  error:   { type: String, default: '' },
  loading: { type: Boolean, default: false },
})

const emit = defineEmits(['login'])

const email    = ref('')
const password = ref('')
const showPw   = ref(false)

function submit() {
  emit('login', { email: email.value.trim(), password: password.value })
}
</script>

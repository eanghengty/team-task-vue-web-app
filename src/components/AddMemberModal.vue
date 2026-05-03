<template>
  <div class="modal-overlay" :class="{ open }" @click.self="$emit('close')">
    <div class="modal p-0" style="max-width:420px">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-2xl tracking-wider">ADD MEMBER</span>
          <button @click="$emit('close')" style="color:var(--muted);display:flex;align-items:center">
            <span class="material-icons" style="font-size:20px">close</span>
          </button>
        </div>
      </div>

      <div class="p-5 flex flex-col gap-4">
        <!-- Name -->
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">FULL NAME *</label>
          <input class="field" v-model="form.name" placeholder="e.g. Alex Kim" />
        </div>

        <!-- Role -->
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">JOB ROLE</label>
          <input class="field" v-model="form.role" placeholder="e.g. Designer" />
        </div>

        <!-- Email -->
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">EMAIL</label>
          <input class="field" type="email" v-model="form.email" placeholder="e.g. alex@company.com" />
        </div>

        <!-- Password -->
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">PASSWORD</label>
          <div class="relative">
            <input
              class="field pr-10"
              :type="showPassword ? 'text' : 'password'"
              v-model="form.password"
              placeholder="Set a login password"
            />
            <button
              type="button"
              class="absolute right-3 top-1/2 -translate-y-1/2"
              style="color:var(--muted);display:flex;align-items:center"
              @click="showPassword = !showPassword"
            >
              <span class="material-icons" style="font-size:18px">{{ showPassword ? 'visibility_off' : 'visibility' }}</span>
            </button>
          </div>
        </div>

        <!-- Access + Color row -->
        <div class="flex gap-3">
          <div class="flex-1">
            <label class="block text-xs font-mono mb-2" style="color:var(--muted)">ACCESS</label>
            <select class="field" v-model="form.access">
              <option value="user">User</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-mono mb-2" style="color:var(--muted)">COLOR</label>
            <div class="flex gap-2 h-[42px] items-center">
              <div v-for="c in colors" :key="c"
                class="w-7 h-7 rounded-full cursor-pointer transition-all"
                :style="{ background: c, border: form.color === c ? '2px solid white' : '2px solid transparent' }"
                @click="form.color = c"
              />
            </div>
          </div>
        </div>

        <div class="flex gap-2 pt-1">
          <button class="btn-primary flex-1" @click="$emit('submit')">Add Member</button>
          <button class="btn-ghost" @click="$emit('close')">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

defineProps({
  open:   Boolean,
  form:   Object,
  colors: Array,
})
defineEmits(['close', 'submit'])

const showPassword = ref(false)
</script>

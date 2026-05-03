<template>
  <div class="modal-overlay" :class="{ open }" @click.self="$emit('close')">
    <div class="modal p-0" style="max-width:400px">
      <div class="p-5" style="border-bottom:1px solid var(--border)">
        <div class="flex items-center justify-between">
          <span class="font-display text-2xl tracking-wider">ADD MEMBER</span>
          <button @click="$emit('close')" style="color:var(--muted);display:flex;align-items:center"><span class="material-icons" style="font-size:20px">close</span></button>
        </div>
      </div>
      <div class="p-5 flex flex-col gap-4">
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">FULL NAME *</label>
          <input class="field" v-model="form.name" placeholder="e.g. Alex Kim" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">ROLE</label>
          <input class="field" v-model="form.role" placeholder="e.g. Designer" />
        </div>
        <div>
          <label class="block text-xs font-mono mb-2" style="color:var(--muted)">COLOR</label>
          <div class="flex gap-2">
            <div v-for="c in colors" :key="c"
              class="w-7 h-7 rounded-full cursor-pointer transition-all"
              :style="{ background: c, border: form.color === c ? '2px solid white' : '2px solid transparent' }"
              @click="form.color = c"></div>
          </div>
        </div>
        <div class="flex gap-2 pt-2">
          <button class="btn-primary flex-1" @click="$emit('submit')">Add Member</button>
          <button class="btn-ghost" @click="$emit('close')">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  open: Boolean,
  form: Object,
  colors: Array,
})
defineEmits(['close', 'submit'])
</script>

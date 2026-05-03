<template>
  <div class="toast-container">
    <div v-for="toast in toasts" :key="toast.id"
      class="toast" :class="{ 'fade-out': toast.fading }"
      :style="{ borderColor: toast.color }">
      <div class="w-2 h-2 rounded-full flex-shrink-0 mt-1" :style="{ background: toast.color }"></div>
      <div class="flex-1 min-w-0">
        <div class="text-sm font-semibold">{{ toast.title }}</div>
        <div class="text-xs mt-0.5 truncate" style="color:var(--muted)">{{ toast.msg }}</div>
      </div>
      <button @click="$emit('remove', toast.id)" style="color:var(--muted);font-size:14px;flex-shrink:0">✕</button>
    </div>
  </div>
</template>

<script setup>
defineProps({ toasts: Array })
defineEmits(['remove'])
</script>

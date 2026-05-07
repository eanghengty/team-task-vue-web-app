<template>
  <div class="px-6 py-3 flex items-center gap-2" style="border-bottom:1px solid var(--border)">
    <button class="tab-btn" :class="{ active: currentTab === 'board' }" @click="$emit('update:currentTab', 'board')">Board</button>
    <button class="tab-btn" :class="{ active: currentTab === 'list' }" @click="$emit('update:currentTab', 'list')">List</button>
    <button class="tab-btn" :class="{ active: currentTab === 'chat' }" @click="$emit('update:currentTab', 'chat')">
      Chat
      <span v-if="chatUnreadCount > 0" class="badge ml-1" style="font-size:10px;padding:1px 6px;background:var(--accent3);color:#fff">
        {{ chatUnreadCount > 99 ? '99+' : chatUnreadCount }}
      </span>
    </button>
    <button class="tab-btn" :class="{ active: currentTab === 'reminders' }" @click="$emit('update:currentTab', 'reminders')">
      Reminders
      <span class="badge badge-yellow ml-1" style="font-size:10px;padding:1px 6px">{{ pendingCount }}</span>
    </button>
    <button v-if="currentUser?.access === 'admin'"
      class="tab-btn" :class="{ active: currentTab === 'activity' }"
      @click="$emit('update:currentTab', 'activity')">
      <span class="material-icons" style="font-size:13px;vertical-align:-2px;margin-right:4px">history</span>Activity Log
    </button>
    <div class="flex-1"></div>
    <div v-if="currentTab !== 'chat'" class="flex items-center gap-2">
      <span class="text-xs" style="color:var(--muted)">Filter:</span>
      <select class="field text-xs" style="width:auto;padding:5px 10px"
        :value="filterMember" @change="$emit('update:filterMember', $event.target.value)">
        <option value="">All Members</option>
        <option v-for="m in members" :key="m.id" :value="m.id">{{ m.name }}</option>
      </select>
      <select class="field text-xs" style="width:auto;padding:5px 10px"
        :value="filterPriority" @change="$emit('update:filterPriority', $event.target.value)">
        <option value="">All Priority</option>
        <option value="high">High</option>
        <option value="medium">Medium</option>
        <option value="low">Low</option>
      </select>
      <div v-if="currentTab === 'list'" class="flex items-center gap-2">
        <span class="text-xs" style="color:var(--muted)">Due:</span>
        <input
          type="date"
          class="field text-xs"
          style="width:auto;padding:5px 10px"
          :value="filterDueFrom"
          @input="$emit('update:filterDueFrom', $event.target.value)"
        />
        <span class="text-xs" style="color:var(--muted)">to</span>
        <input
          type="date"
          class="field text-xs"
          style="width:auto;padding:5px 10px"
          :value="filterDueTo"
          @input="$emit('update:filterDueTo', $event.target.value)"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  currentTab:     String,
  members:        Array,
  filterMember:   String,
  filterPriority: String,
  filterDueFrom:  String,
  filterDueTo:    String,
  pendingCount:   Number,
  chatUnreadCount: Number,
  currentUser:    Object,
})
defineEmits(['update:currentTab', 'update:filterMember', 'update:filterPriority', 'update:filterDueFrom', 'update:filterDueTo'])
</script>

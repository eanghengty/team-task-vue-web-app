<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between">
      <span class="text-xs font-mono" style="color:var(--muted)">{{ total }} ENTRIES</span>
      <button class="btn-ghost text-xs flex items-center gap-1.5" @click="fetchPage(page)">
        <span class="material-icons" style="font-size:14px">refresh</span>
        Refresh
      </button>
    </div>

    <div v-if="loading" class="flex justify-center py-12">
      <span class="material-icons animate-spin" style="color:var(--muted);font-size:28px">refresh</span>
    </div>

    <div v-else class="rounded-lg overflow-hidden" style="border:1px solid var(--border)">
      <table class="w-full text-sm">
        <thead>
          <tr style="background:var(--surface);border-bottom:1px solid var(--border)">
            <th v-for="h in ['WHEN','WHO','ACTION']" :key="h"
              class="text-left p-3 font-mono text-xs" style="color:var(--muted)">{{ h }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="!logs.length">
            <td colspan="3" class="text-center py-8 font-mono text-sm" style="color:var(--muted)">no activity yet</td>
          </tr>
          <tr v-for="log in logs" :key="log.id"
            class="border-b" style="border-color:var(--border);background:var(--surface)">
            <td class="p-3 text-xs font-mono whitespace-nowrap" style="color:var(--muted)">{{ fmtDate(log.created_at) }}</td>
            <td class="p-3">
              <div v-if="log.actor" class="flex items-center gap-2">
                <div class="avatar" style="width:22px;height:22px;font-size:9px"
                  :style="{ background: log.actor.color || '#444', color: '#0d0d0d' }">
                  {{ initials(log.actor.name) }}
                </div>
                <span class="text-xs">{{ log.actor.name }}</span>
              </div>
              <span v-else class="text-xs font-mono" style="color:var(--muted)">—</span>
            </td>
            <td class="p-3 text-sm">{{ log.message }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="totalPages > 1" class="flex items-center justify-center gap-3">
      <button class="btn-ghost text-xs px-3 py-1.5 flex items-center gap-1"
        :disabled="page === 1" @click="fetchPage(page - 1)">
        <span class="material-icons" style="font-size:14px">chevron_left</span> Prev
      </button>
      <span class="text-xs font-mono" style="color:var(--muted)">{{ page }} / {{ totalPages }}</span>
      <button class="btn-ghost text-xs px-3 py-1.5 flex items-center gap-1"
        :disabled="page === totalPages" @click="fetchPage(page + 1)">
        Next <span class="material-icons" style="font-size:14px">chevron_right</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase.js'

const PAGE_SIZE = 20

const logs    = ref([])
const total   = ref(0)
const page    = ref(1)
const loading = ref(false)

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / PAGE_SIZE)))

async function fetchPage(p) {
  loading.value = true
  page.value = p
  const from = (p - 1) * PAGE_SIZE
  const to   = from + PAGE_SIZE - 1

  const [countRes, dataRes] = await Promise.all([
    supabase.from('activity_logs').select('id', { count: 'exact', head: true }),
    supabase.from('activity_logs')
      .select('*, actor:actor_id(id, name, color)')
      .order('created_at', { ascending: false })
      .range(from, to),
  ])
  total.value = countRes.count ?? 0
  logs.value  = dataRes.data ?? []
  loading.value = false
}

function fmtDate(iso) {
  const d = new Date(iso)
  return d.toLocaleDateString('en-AU', { day: '2-digit', month: 'short' }) + ' ' +
         d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })
}

function initials(name) {
  return (name || '?').split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase()
}

onMounted(() => fetchPage(1))
</script>

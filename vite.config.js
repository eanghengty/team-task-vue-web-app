import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: '/team-task-vue-web-app/',
  server: {
    port: 6005,
  },
})

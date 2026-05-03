export const uid = () => '_' + Math.random().toString(36).substr(2, 9)

export const statusLabel = (s) =>
  ({ todo: 'Todo', progress: 'In Progress', review: 'Review', done: 'Done' }[s])

export const statusBadgeClass = (s) =>
  ({ todo: 'badge-gray', progress: 'badge-yellow', review: 'badge-blue', done: 'badge-gray' }[s])

export const priorityDotColor = (p) =>
  ({ high: 'var(--accent2)', medium: 'var(--accent)', low: 'var(--accent3)' }[p])

export const isOverdue = (t) => t.due && !t.done && new Date(t.due) < new Date()

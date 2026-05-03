export const uid = () => '_' + Math.random().toString(36).substr(2, 9)

export const priorityDotColor = (p) =>
  ({ high: 'var(--accent2)', medium: 'var(--accent)', low: 'var(--accent3)' }[p])

export const isOverdue = (t) => t.due && !t.done && new Date(t.due) < new Date()

// Returns an inline badge style derived from a hex dot colour.
export function dotToBadgeStyle(dot) {
  if (!dot || !dot.startsWith('#')) return {}
  return {
    background: dot + '1e',
    color: dot,
    border: `1px solid ${dot}4d`,
    fontFamily: "'DM Mono', monospace",
  }
}

// Slugify a label into a status key: "In Review" → "in_review"
export function labelToKey(label) {
  return label.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')
}

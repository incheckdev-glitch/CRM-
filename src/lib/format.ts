import { format, parseISO } from 'date-fns'

export const money = (value: number | string | null | undefined, currency = 'USD') => {
  const n = Number(value || 0)
  return new Intl.NumberFormat('en-US', { style: 'currency', currency, maximumFractionDigits: 2 }).format(n)
}

export const dateLabel = (value?: string | null) => {
  if (!value) return '—'
  try { return format(parseISO(value), 'dd MMM yyyy') } catch { return value }
}

export const compactDate = (value?: string | null) => {
  if (!value) return '—'
  try { return format(parseISO(value), 'dd MMM') } catch { return value }
}

export const titleCase = (value?: string | null) =>
  value ? value.replaceAll('_', ' ').replace(/\b\w/g, c => c.toUpperCase()) : '—'

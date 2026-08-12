import type { LucideIcon } from 'lucide-react'

export default function StatCard({ label, value, hint, icon: Icon }: { label: string; value: string | number; hint?: string; icon?: LucideIcon }) {
  return (
    <div className="stat-card">
      <div className="stat-icon">{Icon ? <Icon size={20} /> : null}</div>
      <div className="stat-copy">
        <span>{label}</span>
        <strong>{value}</strong>
        {hint && <small>{hint}</small>}
      </div>
    </div>
  )
}

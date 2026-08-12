import { titleCase } from '../lib/format'

export default function StatusBadge({ value }: { value?: string | null }) {
  const normalized = value || 'unknown'
  return <span className={`badge badge-${normalized}`}>{titleCase(normalized)}</span>
}

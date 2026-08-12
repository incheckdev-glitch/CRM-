import { CheckCircle2, AlertCircle } from 'lucide-react'
export default function Toast({ type = 'success', children }: { type?: 'success'|'error'; children: React.ReactNode }) {
  return <div className={`toast toast-${type}`}>{type === 'success' ? <CheckCircle2 size={18}/> : <AlertCircle size={18}/>}<span>{children}</span></div>
}

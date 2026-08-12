import { Inbox } from 'lucide-react'
export default function EmptyState({ title = 'Nothing here yet', text = 'Create the first record to get started.' }: { title?: string; text?: string }) {
  return <div className="empty-state"><Inbox size={30}/><strong>{title}</strong><span>{text}</span></div>
}

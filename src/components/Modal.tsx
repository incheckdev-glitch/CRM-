import { X } from 'lucide-react'

export default function Modal({ open, title, children, onClose, wide = false }: { open: boolean; title: string; children: React.ReactNode; onClose: () => void; wide?: boolean }) {
  if (!open) return null
  return (
    <div className="modal-backdrop" onMouseDown={onClose}>
      <div className={`modal-card ${wide ? 'modal-wide' : ''}`} onMouseDown={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{title}</h2>
          <button className="icon-button" onClick={onClose}><X size={20} /></button>
        </div>
        <div className="modal-body">{children}</div>
      </div>
    </div>
  )
}

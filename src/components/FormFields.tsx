export function Field({ label, children, full = false, help }: { label: string; children: React.ReactNode; full?: boolean; help?: string }) {
  return <label className={`field ${full ? 'field-full' : ''}`}><span>{label}</span>{children}{help && <small>{help}</small>}</label>
}

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input className="input" {...props}/>
}
export function Select(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return <select className="input" {...props}/>
}
export function Textarea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea className="input textarea" {...props}/>
}

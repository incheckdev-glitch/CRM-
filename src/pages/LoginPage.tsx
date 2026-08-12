import { FormEvent, useState } from 'react'
import { supabase } from '../lib/supabase'
import { ArrowRight, Building2, CheckCircle2, LockKeyhole } from 'lucide-react'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const submit = async (e: FormEvent) => {
    e.preventDefault(); setLoading(true); setError('')
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) setError(error.message)
    setLoading(false)
  }

  return <div className="login-shell">
    <section className="login-hero">
      <div className="login-brand"><div className="brand-mark large">R</div><strong>Reseller360</strong></div>
      <div className="hero-copy"><span className="eyebrow">Partner growth, under control</span><h1>One workspace from first prospect to renewal and payment.</h1><p>Give every reseller a private CRM while you retain a complete view of clients, locations, renewals, invoices and cash collection.</p>
      <div className="hero-points"><span><CheckCircle2/>Private reseller workspaces</span><span><CheckCircle2/>Shared company intelligence</span><span><CheckCircle2/>Renewals & finance in one flow</span></div></div>
      <div className="hero-art"><div className="floating-card"><Building2/><div><strong>42 Active Resellers</strong><span>238 active clients</span></div></div><div className="floating-card second"><LockKeyhole/><div><strong>Secure by design</strong><span>Supabase Row Level Security</span></div></div></div>
    </section>
    <section className="login-panel"><form className="login-card" onSubmit={submit}><div><span className="eyebrow">Welcome back</span><h2>Sign in to your workspace</h2><p>Use the account created in Supabase Authentication.</p></div>
      <label className="field"><span>Email</span><input className="input" type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="you@company.com"/></label>
      <label className="field"><span>Password</span><input className="input" type="password" required value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••"/></label>
      {error && <div className="form-error">{error}</div>}
      <button className="btn primary full" disabled={loading}>{loading ? 'Signing in…' : 'Sign in'}<ArrowRight size={18}/></button>
      <small className="login-note">New users are created by the platform administrator.</small>
    </form></section>
  </div>
}

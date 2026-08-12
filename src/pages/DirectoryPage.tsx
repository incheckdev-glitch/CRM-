import { useMemo, useState } from 'react'
import { Globe2, Search, ShieldCheck } from 'lucide-react'
import PageHeader from '../components/PageHeader'
import StatusBadge from '../components/StatusBadge'
import Loading from '../components/Loading'
import EmptyState from '../components/EmptyState'
import { useTableData } from '../hooks/useTableData'

export default function DirectoryPage() {
  const { data, loading } = useTableData<any>('shared_company_directory','*','updated_at')
  const [q,setQ] = useState('')
  const [stage,setStage] = useState('all')
  const rows = useMemo(()=>data.filter(r=>{
    const hit = [r.company_name,r.website,r.country,r.industry,r.reseller_name].join(' ').toLowerCase().includes(q.toLowerCase())
    return hit && (stage==='all' || r.stage===stage)
  }),[data,q,stage])

  return <>
    <PageHeader title="Shared Market Directory" subtitle="See who is being worked, by whom, and at which stage—without exposing private contacts, notes or deal values."/>
    <div className="info-banner"><ShieldCheck size={20}/><div><strong>Shared intelligence, private CRM.</strong><span>Other resellers can see company identity and relationship status only. Editing remains with the owning reseller.</span></div></div>
    <div className="toolbar"><div className="search-box"><Search size={18}/><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search company, country, industry or reseller…"/></div><select className="input compact" value={stage} onChange={e=>setStage(e.target.value)}><option value="all">All stages</option><option value="not_contacted">Not contacted</option><option value="contacted">Contacted</option><option value="engaged">Engaged</option><option value="qualified">Qualified</option><option value="proposal">Proposal</option><option value="negotiation">Negotiation</option><option value="won">Customer / Won</option><option value="lost">Lost</option></select></div>
    {loading ? <Loading/> : rows.length ? <div className="directory-grid">{rows.map(r=><article className="company-card" key={`${r.company_id}-${r.reseller_id||'none'}`}><div className="company-card-top"><div className="company-logo"><Globe2 size={20}/></div><StatusBadge value={r.stage || 'not_contacted'}/></div><h3>{r.company_name}</h3><p>{[r.industry,r.country].filter(Boolean).join(' · ') || 'Company details not completed'}</p><div className="company-meta"><div><span>Contacted</span><strong>{r.contacted ? 'Yes' : 'No'}</strong></div><div><span>Handled by</span><strong>{r.reseller_name || 'Available'}</strong></div><div><span>Active client</span><strong>{r.is_active_client ? 'Yes' : 'No'}</strong></div></div>{r.website && <a className="text-link" href={r.website.startsWith('http')?r.website:`https://${r.website}`} target="_blank">Visit website →</a>}</article>)}</div> : <EmptyState title="No companies found" text="Try another search or add companies from My Companies."/>}
  </>
}

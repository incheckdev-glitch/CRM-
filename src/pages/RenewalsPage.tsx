import { useMemo, useState } from 'react'
import { RefreshCw, Search, FilePlus2 } from 'lucide-react'
import PageHeader from '../components/PageHeader'
import Loading from '../components/Loading'
import EmptyState from '../components/EmptyState'
import StatusBadge from '../components/StatusBadge'
import { useTableData } from '../hooks/useTableData'
import { supabase } from '../lib/supabase'
import { dateLabel, money } from '../lib/format'
import { useAuth } from '../contexts/AuthContext'

export default function RenewalsPage(){
 const {isAdmin}=useAuth(); const {data,loading,refresh}=useTableData<any>('renewal_overview','*','expiry_date'); const [q,setQ]=useState(''); const [busy,setBusy]=useState<string|null>(null); const [filter,setFilter]=useState('all')
 const rows=useMemo(()=>data.filter(r=>[r.client_name,r.location_name,r.reseller_name,r.status].join(' ').toLowerCase().includes(q.toLowerCase())&&(filter==='all'||r.status===filter)),[data,q,filter])
 const requestRenewal=async(id:string)=>{setBusy(id);const {error}=await supabase.rpc('request_renewal',{p_renewal_id:id});if(error)alert(error.message);await refresh();setBusy(null)}
 const issue=async(id:string)=>{setBusy(id);const {error}=await supabase.rpc('issue_renewal_invoice',{p_renewal_id:id});if(error)alert(error.message);await refresh();setBusy(null)}
 return <><PageHeader title="Renewals" subtitle="Track every expiring licence from upcoming through requested, invoiced, paid and renewed."/><div className="toolbar"><div className="search-box"><Search size={18}/><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search renewals…"/></div><select className="input compact" value={filter} onChange={e=>setFilter(e.target.value)}><option value="all">All statuses</option>{['upcoming','requested','approved','invoiced','renewed','not_renewing','expired'].map(s=><option key={s} value={s}>{s.replaceAll('_',' ')}</option>)}</select></div>{loading?<Loading/>:rows.length?<div className="panel table-panel"><div className="table-wrap"><table><thead><tr><th>Client / Location</th><th>Reseller</th><th>Expiry</th><th>Renewal value</th><th>Status</th><th></th></tr></thead><tbody>{rows.map(r=><tr key={r.id}><td><strong>{r.client_name}</strong><small>{r.location_name} · {r.product_name}</small></td><td>{r.reseller_name}</td><td>{dateLabel(r.expiry_date)}<small>{r.days_to_expiry} day(s)</small></td><td>{money(r.renewal_value,r.currency)}<small>{r.billing_frequency?.replaceAll('_',' ')} · Net {r.payment_term_days}</small></td><td><StatusBadge value={r.status}/></td><td className="actions-cell">{['upcoming'].includes(r.status)&&<button className="btn small secondary" disabled={busy===r.id} onClick={()=>requestRenewal(r.id)}><RefreshCw size={15}/>Request</button>}{isAdmin&&['requested','approved'].includes(r.status)&&<button className="btn small primary" disabled={busy===r.id} onClick={()=>issue(r.id)}><FilePlus2 size={15}/>Issue invoice</button>}</td></tr>)}</tbody></table></div></div>:<EmptyState title="No renewals found"/>}</>
}

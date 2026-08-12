import { Search, Store, MapPin, RefreshCw } from 'lucide-react'
import { useMemo, useState } from 'react'
import PageHeader from '../components/PageHeader'
import Loading from '../components/Loading'
import EmptyState from '../components/EmptyState'
import StatusBadge from '../components/StatusBadge'
import { useTableData } from '../hooks/useTableData'
import { dateLabel, money } from '../lib/format'

export default function ClientsPage(){
 const {data,loading}=useTableData<any>('client_overview','*','created_at'); const [q,setQ]=useState('')
 const rows=useMemo(()=>data.filter(r=>[r.client_name,r.reseller_name,r.country,r.status].join(' ').toLowerCase().includes(q.toLowerCase())),[data,q])
 return <><PageHeader title="Active Clients" subtitle="Portfolio view of won customers, active locations, licence value and next renewals."/><div className="toolbar"><div className="search-box"><Search size={18}/><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search clients…"/></div></div>{loading?<Loading/>:rows.length?<div className="client-grid">{rows.map(r=><article className="client-card" key={r.id}><div className="client-card-head"><div className="company-logo"><Store size={19}/></div><StatusBadge value={r.status}/></div><h3>{r.client_name}</h3><p>{[r.industry,r.country].filter(Boolean).join(' · ')||'Client profile'}</p><div className="client-kpis"><div><MapPin size={16}/><span>Locations</span><strong>{r.active_locations||0}</strong></div><div><RefreshCw size={16}/><span>Next renewal</span><strong>{dateLabel(r.next_renewal_date)}</strong></div></div><div className="client-value"><span>Active licence value</span><strong>{money(r.active_value,r.currency)}</strong></div>{r.reseller_name&&<small className="owner-line">Reseller: {r.reseller_name}</small>}</article>)}</div>:<EmptyState title="No active clients yet" text="Clients are created when an approved new-client request is converted."/>}</>
}

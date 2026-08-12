import { Search, MapPin } from 'lucide-react'
import { useMemo, useState } from 'react'
import PageHeader from '../components/PageHeader'
import Loading from '../components/Loading'
import EmptyState from '../components/EmptyState'
import StatusBadge from '../components/StatusBadge'
import { useTableData } from '../hooks/useTableData'
import { dateLabel, money, titleCase } from '../lib/format'

export default function LocationsPage(){
 const {data,loading}=useTableData<any>('location_license_overview','*','created_at'); const [q,setQ]=useState('')
 const rows=useMemo(()=>data.filter(r=>[r.location_name,r.client_name,r.product_name,r.country,r.status].join(' ').toLowerCase().includes(q.toLowerCase())),[data,q])
 return <><PageHeader title="Locations & Licences" subtitle="Every active client location, subscription period, billing frequency and expiry in one operational view."/><div className="toolbar"><div className="search-box"><Search size={18}/><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search locations or licences…"/></div></div>{loading?<Loading/>:rows.length?<div className="panel table-panel"><div className="table-wrap"><table><thead><tr><th>Client / Location</th><th>Licence</th><th>Period</th><th>Billing</th><th>Value</th><th>Status</th></tr></thead><tbody>{rows.map(r=><tr key={r.license_id}><td><strong>{r.location_name}</strong><small>{r.client_name} · {[r.city,r.country].filter(Boolean).join(', ')}</small></td><td>{r.product_name}<small>{r.quantity} licence(s)</small></td><td>{dateLabel(r.start_date)}<small>to {dateLabel(r.expiry_date)}</small></td><td>{titleCase(r.billing_frequency)}<small>Net {r.payment_term_days||0}</small></td><td>{money(r.annual_value,r.currency)}</td><td><StatusBadge value={r.status}/></td></tr>)}</tbody></table></div></div>:<EmptyState title="No locations yet" text="Approved client/location requests create locations and licences automatically."/>}</>
}

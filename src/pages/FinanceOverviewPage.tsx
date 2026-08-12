import { useMemo, useState } from 'react'
import { CircleDollarSign, Search, WalletCards, BadgeDollarSign, Clock3 } from 'lucide-react'
import PageHeader from '../components/PageHeader'
import StatCard from '../components/StatCard'
import Loading from '../components/Loading'
import { useTableData } from '../hooks/useTableData'
import { money } from '../lib/format'

export default function FinanceOverviewPage(){
 const {data,loading}=useTableData<any>('reseller_finance_summary','*','reseller_name'); const [q,setQ]=useState('')
 const rows=useMemo(()=>data.filter(r=>r.reseller_name?.toLowerCase().includes(q.toLowerCase())),[data,q]); const total=rows.reduce((s,r)=>s+Number(r.invoiced||0),0);const paid=rows.reduce((s,r)=>s+Number(r.paid||0),0);const outstanding=rows.reduce((s,r)=>s+Number(r.outstanding||0),0);const overdue=rows.reduce((s,r)=>s+Number(r.overdue||0),0)
 return <><PageHeader title="Finance Overview" subtitle="Consolidated reseller billing and collection position."/><div className="stats-grid"><StatCard label="Total invoiced" value={money(total)} icon={CircleDollarSign}/><StatCard label="Paid" value={money(paid)} icon={BadgeDollarSign}/><StatCard label="Outstanding" value={money(outstanding)} icon={WalletCards}/><StatCard label="Overdue" value={money(overdue)} icon={Clock3}/></div><div className="toolbar"><div className="search-box"><Search size={18}/><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search reseller…"/></div></div>{loading?<Loading/>:<div className="panel table-panel"><div className="table-wrap"><table><thead><tr><th>Reseller</th><th>Invoiced</th><th>Paid</th><th>Outstanding</th><th>Overdue</th><th>Expected 30d</th><th>Expected 90d</th></tr></thead><tbody>{rows.map(r=><tr key={r.reseller_id}><td><strong>{r.reseller_name}</strong></td><td>{money(r.invoiced,r.currency)}</td><td>{money(r.paid,r.currency)}</td><td><strong>{money(r.outstanding,r.currency)}</strong></td><td className={Number(r.overdue)>0?'danger-text':''}>{money(r.overdue,r.currency)}</td><td>{money(r.expected_30d,r.currency)}</td><td>{money(r.expected_90d,r.currency)}</td></tr>)}</tbody></table></div></div>}</>
}

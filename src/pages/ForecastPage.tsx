import { useMemo, useState } from 'react'
import { CalendarClock, Search, TrendingUp, WalletCards } from 'lucide-react'
import PageHeader from '../components/PageHeader'
import StatCard from '../components/StatCard'
import Loading from '../components/Loading'
import EmptyState from '../components/EmptyState'
import StatusBadge from '../components/StatusBadge'
import { useTableData } from '../hooks/useTableData'
import { dateLabel, money } from '../lib/format'

export default function ForecastPage(){
 const {data,loading}=useTableData<any>('payment_schedule_overview','*','due_date'); const [q,setQ]=useState(''); const [scope,setScope]=useState('all')
 const today=new Date(); const startMonth=new Date(today.getFullYear(),today.getMonth(),1); const endMonth=new Date(today.getFullYear(),today.getMonth()+1,0)
 const rows=useMemo(()=>data.filter(r=>{const d=new Date(r.due_date);const hit=[r.invoice_number,r.reseller_name,r.client_name,r.status].join(' ').toLowerCase().includes(q.toLowerCase()); if(!hit)return false;if(scope==='month')return d>=startMonth&&d<=endMonth;if(scope==='overdue')return r.status==='overdue';return true}),[data,q,scope])
 const expected=rows.reduce((s,r)=>s+Number(r.amount_due||0),0); const received=rows.reduce((s,r)=>s+Number(r.paid_amount||0),0); const balance=rows.reduce((s,r)=>s+Number(r.balance||0),0)
 return <><PageHeader title="Payment Forecast" subtitle="Expected cash is calculated from each invoice installment and its payment terms—not simply from total contract value."/><div className="stats-grid three"><StatCard label="Expected" value={money(expected)} icon={CalendarClock}/><StatCard label="Allocated payments" value={money(received)} icon={WalletCards}/><StatCard label="Remaining" value={money(balance)} icon={TrendingUp}/></div><div className="toolbar"><div className="search-box"><Search size={18}/><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search reseller, invoice or client…"/></div><select className="input compact" value={scope} onChange={e=>setScope(e.target.value)}><option value="all">All scheduled</option><option value="month">This month</option><option value="overdue">Overdue only</option></select></div>{loading?<Loading/>:rows.length?<div className="panel table-panel"><div className="table-wrap"><table><thead><tr><th>Due date</th><th>Reseller</th><th>Invoice / Client</th><th>Installment</th><th>Expected</th><th>Received</th><th>Balance</th><th>Status</th></tr></thead><tbody>{rows.map(r=><tr key={r.id}><td>{dateLabel(r.due_date)}</td><td><strong>{r.reseller_name}</strong></td><td>{r.invoice_number}<small>{r.client_name||r.location_name||'—'}</small></td><td>{r.installment_number}/{r.installment_count}</td><td>{money(r.amount_due,r.currency)}</td><td>{money(r.paid_amount,r.currency)}</td><td><strong>{money(r.balance,r.currency)}</strong></td><td><StatusBadge value={r.status}/></td></tr>)}</tbody></table></div></div>:<EmptyState title="No scheduled payments found"/>}</>
}

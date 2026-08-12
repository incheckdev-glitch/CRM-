import { useMemo, useState } from 'react'
import { Landmark, Search } from 'lucide-react'
import PageHeader from '../components/PageHeader'
import StatCard from '../components/StatCard'
import Loading from '../components/Loading'
import EmptyState from '../components/EmptyState'
import { useTableData } from '../hooks/useTableData'
import { dateLabel, money } from '../lib/format'

export default function StatementsPage(){
 const {data,loading}=useTableData<any>('reseller_statement','*','entry_date'); const [q,setQ]=useState('')
 const rows=useMemo(()=>data.filter(r=>[r.reseller_name,r.document_number,r.description].join(' ').toLowerCase().includes(q.toLowerCase())),[data,q]); const debit=rows.reduce((s,r)=>s+Number(r.debit||0),0);const credit=rows.reduce((s,r)=>s+Number(r.credit||0),0)
 return <><PageHeader title="Statements of Account" subtitle="Invoice debits and receipt credits combined into one reseller accounting history."/><div className="stats-grid three"><StatCard label="Debits" value={money(debit)} icon={Landmark}/><StatCard label="Credits" value={money(credit)} icon={Landmark}/><StatCard label="Net balance" value={money(debit-credit)} icon={Landmark}/></div><div className="toolbar"><div className="search-box"><Search size={18}/><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search reseller or document…"/></div></div>{loading?<Loading/>:rows.length?<div className="panel table-panel"><div className="table-wrap"><table><thead><tr><th>Date</th><th>Reseller</th><th>Document</th><th>Description</th><th>Debit</th><th>Credit</th><th>Running balance</th></tr></thead><tbody>{rows.map((r,i)=><tr key={`${r.entry_type}-${r.entry_id}-${i}`}><td>{dateLabel(r.entry_date)}</td><td>{r.reseller_name}</td><td><strong>{r.document_number}</strong></td><td>{r.description}</td><td>{r.debit?money(r.debit,r.currency):'—'}</td><td>{r.credit?money(r.credit,r.currency):'—'}</td><td><strong>{money(r.running_balance,r.currency)}</strong></td></tr>)}</tbody></table></div></div>:<EmptyState title="No statement entries"/>}</>
}

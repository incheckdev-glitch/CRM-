import { useEffect, useState } from 'react'
import { Building2, Handshake, RefreshCw, ReceiptText, Store, WalletCards } from 'lucide-react'
import PageHeader from '../components/PageHeader'
import StatCard from '../components/StatCard'
import Loading from '../components/Loading'
import StatusBadge from '../components/StatusBadge'
import { supabase } from '../lib/supabase'
import { money, dateLabel } from '../lib/format'
import { useAuth } from '../contexts/AuthContext'

export default function DashboardPage() {
  const { profile } = useAuth()
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<any>({})
  const [renewals, setRenewals] = useState<any[]>([])
  const [forecast, setForecast] = useState<any[]>([])

  useEffect(() => { (async () => {
    setLoading(true)
    const [companies, deals, clients, renewalRows, invoiceRows, forecastRows] = await Promise.all([
      supabase.from('reseller_company_links').select('*', { count: 'exact', head: true }),
      supabase.from('deals').select('id,value,stage'),
      supabase.from('clients').select('*', { count: 'exact', head: true }).eq('status','active'),
      supabase.from('renewal_overview').select('*').order('expiry_date').limit(6),
      supabase.from('invoice_financials').select('balance,status'),
      supabase.from('payment_schedule_overview').select('*').gte('due_date', new Date().toISOString().slice(0,10)).order('due_date').limit(6),
    ])
    const dealRows = deals.data || []
    const invRows = invoiceRows.data || []
    setStats({
      companies: companies.count || 0,
      activeDeals: dealRows.filter((d:any)=>!['won','lost'].includes(d.stage)).length,
      pipeline: dealRows.filter((d:any)=>!['won','lost'].includes(d.stage)).reduce((s:number,d:any)=>s+Number(d.value||0),0),
      clients: clients.count || 0,
      outstanding: invRows.reduce((s:number,i:any)=>s+Number(i.balance||0),0),
      renewals30: (renewalRows.data || []).filter((r:any)=>new Date(r.expiry_date).getTime() <= Date.now()+30*86400000).length,
    })
    setRenewals(renewalRows.data || [])
    setForecast(forecastRows.data || [])
    setLoading(false)
  })() }, [])

  if (loading) return <Loading label="Loading dashboard"/>
  return <>
    <PageHeader title={`Good morning${profile?.full_name ? `, ${profile.full_name.split(' ')[0]}` : ''}`} subtitle="Here is what needs your attention across CRM, renewals and finance."/>
    <div className="stats-grid">
      <StatCard label="Companies" value={stats.companies} hint="In your CRM" icon={Building2}/>
      <StatCard label="Active Deals" value={stats.activeDeals} hint={money(stats.pipeline) + ' pipeline'} icon={Handshake}/>
      <StatCard label="Active Clients" value={stats.clients} hint="Current portfolio" icon={Store}/>
      <StatCard label="Renewals ≤30d" value={stats.renewals30} hint="Upcoming expiries" icon={RefreshCw}/>
      <StatCard label="Outstanding" value={money(stats.outstanding)} hint="Across issued invoices" icon={WalletCards}/>
      <StatCard label="Receipts" value="Live" hint="Payment-to-receipt flow" icon={ReceiptText}/>
    </div>

    <div className="dashboard-grid">
      <section className="panel">
        <div className="panel-title"><div><h2>Upcoming renewals</h2><p>Prioritize expiring licences and locations.</p></div></div>
        <div className="table-wrap"><table><thead><tr><th>Client / Location</th><th>Expiry</th><th>Value</th><th>Status</th></tr></thead><tbody>
          {renewals.map(r=><tr key={r.id}><td><strong>{r.client_name}</strong><small>{r.location_name}</small></td><td>{dateLabel(r.expiry_date)}</td><td>{money(r.renewal_value,r.currency)}</td><td><StatusBadge value={r.status}/></td></tr>)}
          {!renewals.length && <tr><td colSpan={4} className="empty-cell">No upcoming renewals.</td></tr>}
        </tbody></table></div>
      </section>
      <section className="panel">
        <div className="panel-title"><div><h2>Next expected payments</h2><p>Cash forecast based on installment due dates.</p></div></div>
        <div className="timeline-list">
          {forecast.map(row=><div className="timeline-row" key={row.id}><div className="timeline-dot"/><div className="timeline-copy"><strong>{row.reseller_name}</strong><span>{row.invoice_number} · {row.client_name || 'Direct reseller invoice'}</span></div><div className="timeline-amount"><strong>{money(row.amount_due,row.currency)}</strong><span>{dateLabel(row.due_date)}</span></div></div>)}
          {!forecast.length && <div className="empty-cell">No expected payments found.</div>}
        </div>
      </section>
    </div>
  </>
}

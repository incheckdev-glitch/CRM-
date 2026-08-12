import { FormEvent, useState } from 'react'
import { Plus, Search, Pencil } from 'lucide-react'
import PageHeader from '../components/PageHeader'
import Modal from '../components/Modal'
import Loading from '../components/Loading'
import EmptyState from '../components/EmptyState'
import StatusBadge from '../components/StatusBadge'
import { Field, Input, Select } from '../components/FormFields'
import { useTableData } from '../hooks/useTableData'
import { supabase } from '../lib/supabase'
import { titleCase } from '../lib/format'

const emptyForm = { company_name:'', legal_name:'', website:'', country:'', city:'', industry:'', stage:'not_contacted', contacted:false }

export default function CompaniesPage() {
  const { data, loading, refresh } = useTableData<any>('my_company_overview','*','updated_at')
  const [q,setQ] = useState('')
  const [open,setOpen] = useState(false)
  const [editing,setEditing] = useState<any>(null)
  const [form,setForm] = useState<any>(emptyForm)
  const [saving,setSaving] = useState(false)
  const [error,setError] = useState('')

  const startAdd=()=>{setEditing(null);setForm(emptyForm);setError('');setOpen(true)}
  const startEdit=(r:any)=>{setEditing(r);setForm({ company_name:r.company_name, legal_name:r.legal_name||'', website:r.website||'', country:r.country||'', city:r.city||'', industry:r.industry||'', stage:r.stage, contacted:r.contacted });setError('');setOpen(true)}
  const submit=async(e:FormEvent)=>{e.preventDefault();setSaving(true);setError('')
    if(editing){
      const {error:e1}=await supabase.from('reseller_company_links').update({stage:form.stage,contacted:form.contacted}).eq('id',editing.link_id)
      if(e1) setError(e1.message); else {setOpen(false);await refresh()}
    } else {
      const {error:e1}=await supabase.rpc('create_or_claim_company',{p_name:form.company_name,p_legal_name:form.legal_name||null,p_website:form.website||null,p_country:form.country||null,p_city:form.city||null,p_industry:form.industry||null,p_stage:form.stage})
      if(e1) setError(e1.message); else {setOpen(false);await refresh()}
    }
    setSaving(false)
  }
  const rows=data.filter(r=>[r.company_name,r.country,r.industry,r.stage].join(' ').toLowerCase().includes(q.toLowerCase()))
  return <>
    <PageHeader title="My Companies" subtitle="Your reseller-owned company relationships and prospect stages." actions={<button className="btn primary" onClick={startAdd}><Plus size={18}/>Add company</button>}/>
    <div className="toolbar"><div className="search-box"><Search size={18}/><input placeholder="Search your companies…" value={q} onChange={e=>setQ(e.target.value)}/></div></div>
    {loading?<Loading/>:rows.length?<div className="panel table-panel"><div className="table-wrap"><table><thead><tr><th>Company</th><th>Market</th><th>Stage</th><th>Contacted</th><th>Client?</th><th></th></tr></thead><tbody>{rows.map(r=><tr key={r.link_id}><td><strong>{r.company_name}</strong><small>{r.website||r.legal_name||'—'}</small></td><td>{[r.city,r.country].filter(Boolean).join(', ')||'—'}<small>{r.industry||'—'}</small></td><td><StatusBadge value={r.stage}/></td><td>{r.contacted?'Yes':'No'}</td><td>{r.is_active_client?'Active client':'Prospect'}</td><td className="actions-cell"><button className="icon-button" onClick={()=>startEdit(r)} title="Update relationship"><Pencil size={17}/></button></td></tr>)}</tbody></table></div></div>:<EmptyState title="No companies yet" text="Add a company to start building your reseller pipeline."/>}
    <Modal open={open} onClose={()=>setOpen(false)} title={editing?'Update company relationship':'Add company'}><form onSubmit={submit} className="form-grid">
      <Field label="Company name" full><Input required disabled={!!editing} value={form.company_name} onChange={e=>setForm({...form,company_name:e.target.value})}/></Field>
      {!editing&&<><Field label="Legal name"><Input value={form.legal_name} onChange={e=>setForm({...form,legal_name:e.target.value})}/></Field><Field label="Website"><Input value={form.website} onChange={e=>setForm({...form,website:e.target.value})}/></Field><Field label="Country"><Input value={form.country} onChange={e=>setForm({...form,country:e.target.value})}/></Field><Field label="City"><Input value={form.city} onChange={e=>setForm({...form,city:e.target.value})}/></Field><Field label="Industry" full><Input value={form.industry} onChange={e=>setForm({...form,industry:e.target.value})}/></Field></>}
      <Field label="Pipeline stage"><Select value={form.stage} onChange={e=>setForm({...form,stage:e.target.value})}>{['not_contacted','contacted','engaged','qualified','proposal','negotiation','won','lost'].map(s=><option value={s} key={s}>{titleCase(s)}</option>)}</Select></Field>
      <Field label="Contact status"><Select value={form.contacted?'yes':'no'} onChange={e=>setForm({...form,contacted:e.target.value==='yes'})}><option value="no">Not contacted</option><option value="yes">Contacted</option></Select></Field>
      {error&&<div className="form-error field-full">{error}</div>}<div className="form-actions field-full"><button type="button" className="btn secondary" onClick={()=>setOpen(false)}>Cancel</button><button className="btn primary" disabled={saving}>{saving?'Saving…':'Save'}</button></div>
    </form></Modal>
  </>
}

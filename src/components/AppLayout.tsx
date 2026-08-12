import { NavLink, Outlet } from 'react-router-dom'
import { useState } from 'react'
import {
  LayoutDashboard, Building2, Users, UserRoundSearch, Handshake, Globe2,
  Store, MapPin, RefreshCw, ClipboardList, FileText, CalendarClock, Activity,
  ReceiptText, Landmark, Network, LogOut, Menu, X, Moon, Sun,
  ChevronDown, CircleDollarSign
} from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'

const coreNav = [
  ['/dashboard','Dashboard',LayoutDashboard],
  ['/directory','Shared Market',Globe2],
]
const crmNav = [
  ['/companies','Companies',Building2],
  ['/contacts','Contacts',Users],
  ['/leads','Leads',UserRoundSearch],
  ['/deals','Deals',Handshake],
  ['/activities','Activities',Activity],
]
const clientNav = [
  ['/clients','Active Clients',Store],
  ['/locations','Locations & Licences',MapPin],
  ['/renewals','Renewals',RefreshCw],
  ['/requests','Requests',ClipboardList],
]
const financeNav = [
  ['/invoices','Invoices',FileText],
  ['/forecast','Payment Forecast',CalendarClock],
  ['/receipts','Receipts',ReceiptText],
  ['/statements','Statements',Landmark],
]

function NavSection({ title, items, onNavigate }: { title: string; items: any[]; onNavigate: () => void }) {
  return <div className="nav-section"><span className="nav-label">{title}</span>{items.map(([to,label,Icon]) => (
    <NavLink key={to} to={to} onClick={onNavigate} className={({isActive}) => `nav-item ${isActive ? 'active' : ''}`}>
      <Icon size={18}/><span>{label}</span>
    </NavLink>
  ))}</div>
}

export default function AppLayout() {
  const { profile, signOut, isAdmin } = useAuth()
  const [mobileOpen, setMobileOpen] = useState(false)
  const [dark, setDark] = useState(() => localStorage.getItem('r360-theme') === 'dark')

  const toggleTheme = () => {
    const next = !dark
    setDark(next)
    document.documentElement.dataset.theme = next ? 'dark' : 'light'
    localStorage.setItem('r360-theme', next ? 'dark' : 'light')
  }
  if (typeof document !== 'undefined') document.documentElement.dataset.theme = dark ? 'dark' : 'light'

  const close = () => setMobileOpen(false)
  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileOpen ? 'open' : ''}`}>
        <div className="brand"><div className="brand-mark">R</div><div><strong>Reseller360</strong><span>CRM & Partner Ops</span></div><button className="mobile-close" onClick={close}><X/></button></div>
        <nav className="nav-scroll">
          <NavSection title="Workspace" items={coreNav} onNavigate={close}/>
          <NavSection title="CRM" items={crmNav} onNavigate={close}/>
          <NavSection title="Clients" items={clientNav} onNavigate={close}/>
          <NavSection title="Finance" items={financeNav} onNavigate={close}/>
          {isAdmin && <NavSection title="Administration" items={[["/resellers","Resellers 360",Network],["/finance-overview","Finance Overview",CircleDollarSign]]} onNavigate={close}/>} 
        </nav>
        <div className="sidebar-footer">
          <div className="profile-mini"><div className="avatar">{(profile?.full_name || profile?.email || 'U')[0].toUpperCase()}</div><div><strong>{profile?.full_name || 'User'}</strong><span>{profile?.reseller?.name || (isAdmin ? 'Platform Admin' : 'Unassigned')}</span></div></div>
          <button className="nav-item button-reset" onClick={() => signOut()}><LogOut size={18}/><span>Sign out</span></button>
        </div>
      </aside>
      {mobileOpen && <div className="sidebar-overlay" onClick={close}/>} 
      <div className="app-main">
        <header className="topbar">
          <button className="icon-button mobile-menu" onClick={() => setMobileOpen(true)}><Menu/></button>
          <div className="topbar-spacer"/>
          <button className="icon-button" onClick={toggleTheme} aria-label="Toggle theme">{dark ? <Sun size={19}/> : <Moon size={19}/>}</button>
          <div className="account-chip"><div className="avatar small">{(profile?.full_name || profile?.email || 'U')[0].toUpperCase()}</div><span>{profile?.full_name || profile?.email}</span><ChevronDown size={15}/></div>
        </header>
        <main className="content"><Outlet/></main>
      </div>
    </div>
  )
}

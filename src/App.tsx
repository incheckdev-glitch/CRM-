import { Navigate, Route, Routes } from 'react-router-dom'
import { useAuth } from './contexts/AuthContext'
import AppLayout from './components/AppLayout'
import Loading from './components/Loading'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import DirectoryPage from './pages/DirectoryPage'
import CompaniesPage from './pages/CompaniesPage'
import ContactsPage from './pages/ContactsPage'
import LeadsPage from './pages/LeadsPage'
import DealsPage from './pages/DealsPage'
import ActivitiesPage from './pages/ActivitiesPage'
import ClientsPage from './pages/ClientsPage'
import LocationsPage from './pages/LocationsPage'
import RenewalsPage from './pages/RenewalsPage'
import RequestsPage from './pages/RequestsPage'
import InvoicesPage from './pages/InvoicesPage'
import ForecastPage from './pages/ForecastPage'
import ReceiptsPage from './pages/ReceiptsPage'
import StatementsPage from './pages/StatementsPage'
import ResellersPage from './pages/ResellersPage'
import FinanceOverviewPage from './pages/FinanceOverviewPage'

function AdminOnly({ children }: { children: React.ReactNode }) {
  const { isAdmin } = useAuth()
  return isAdmin ? <>{children}</> : <Navigate to="/dashboard" replace/>
}

export default function App() {
  const { session, loading } = useAuth()
  if (loading) return <div className="center-screen"><Loading label="Opening Reseller360"/></div>
  if (!session) return <Routes><Route path="*" element={<LoginPage/>}/></Routes>

  return (
    <Routes>
      <Route element={<AppLayout/>}>
        <Route path="/dashboard" element={<DashboardPage/>}/>
        <Route path="/directory" element={<DirectoryPage/>}/>
        <Route path="/companies" element={<CompaniesPage/>}/>
        <Route path="/contacts" element={<ContactsPage/>}/>
        <Route path="/leads" element={<LeadsPage/>}/>
        <Route path="/deals" element={<DealsPage/>}/>
        <Route path="/activities" element={<ActivitiesPage/>}/>
        <Route path="/clients" element={<ClientsPage/>}/>
        <Route path="/locations" element={<LocationsPage/>}/>
        <Route path="/renewals" element={<RenewalsPage/>}/>
        <Route path="/requests" element={<RequestsPage/>}/>
        <Route path="/invoices" element={<InvoicesPage/>}/>
        <Route path="/forecast" element={<ForecastPage/>}/>
        <Route path="/receipts" element={<ReceiptsPage/>}/>
        <Route path="/statements" element={<StatementsPage/>}/>
        <Route path="/resellers" element={<AdminOnly><ResellersPage/></AdminOnly>}/>
        <Route path="/finance-overview" element={<AdminOnly><FinanceOverviewPage/></AdminOnly>}/>
      </Route>
      <Route path="*" element={<Navigate to="/dashboard" replace/>}/>
    </Routes>
  )
}

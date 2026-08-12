import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'
import type { Profile } from '../lib/types'

interface AuthState {
  session: Session | null
  user: User | null
  profile: Profile | null
  loading: boolean
  isAdmin: boolean
  resellerId: string | null
  refreshProfile: () => Promise<void>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthState | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)

  const loadProfile = async (userId?: string) => {
    const id = userId || session?.user.id
    if (!id) { setProfile(null); return }
    const { data, error } = await supabase
      .from('profiles')
      .select('id,email,full_name,role,reseller_id,is_active,reseller:resellers(id,name,code)')
      .eq('id', id)
      .single()
    if (error) {
      console.error('Profile load failed', error)
      setProfile(null)
      return
    }
    setProfile(data as unknown as Profile)
  }

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data }) => {
      setSession(data.session)
      if (data.session?.user) await loadProfile(data.session.user.id)
      setLoading(false)
    })

    const { data: subscription } = supabase.auth.onAuthStateChange(async (_event, newSession) => {
      setSession(newSession)
      if (newSession?.user) await loadProfile(newSession.user.id)
      else setProfile(null)
      setLoading(false)
    })

    return () => subscription.subscription.unsubscribe()
  }, [])

  const value = useMemo<AuthState>(() => ({
    session,
    user: session?.user || null,
    profile,
    loading,
    isAdmin: profile?.role === 'admin' || profile?.role === 'finance',
    resellerId: profile?.reseller_id || null,
    refreshProfile: () => loadProfile(),
    signOut: async () => { await supabase.auth.signOut() },
  }), [session, profile, loading])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth must be used inside AuthProvider')
  return value
}

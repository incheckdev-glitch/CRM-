import { createClient } from '@supabase/supabase-js'

const cleanEnv = (value?: string) => value?.trim().replace(/^['"]|['"]$/g, '') || ''

const supabaseUrl = cleanEnv(import.meta.env.VITE_SUPABASE_URL)
const supabaseBrowserKey = cleanEnv(
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY,
)

const hasValidUrl = (() => {
  try {
    return new URL(supabaseUrl).protocol === 'https:'
  } catch {
    return false
  }
})()

export const supabaseConfigured = Boolean(hasValidUrl && supabaseBrowserKey)
export const supabaseConfigurationMessage =
  'Supabase is not configured for this deployment. Add VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY (or VITE_SUPABASE_ANON_KEY) in Vercel Environment Variables, then redeploy.'

if (!supabaseConfigured) {
  console.error(supabaseConfigurationMessage)
}

export const supabase = createClient(
  supabaseConfigured ? supabaseUrl : 'https://placeholder.supabase.co',
  supabaseConfigured ? supabaseBrowserKey : 'placeholder',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  },
)

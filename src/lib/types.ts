export type Role = 'admin' | 'reseller_admin' | 'reseller_user' | 'finance'

export interface Profile {
  id: string
  email: string | null
  full_name: string | null
  role: Role
  reseller_id: string | null
  is_active: boolean
  reseller?: { id: string; name: string; code: string } | null
}

export type BillingFrequency = 'annual' | 'semi_annual' | 'quarterly' | 'monthly'
export type PipelineStage = 'not_contacted' | 'contacted' | 'engaged' | 'qualified' | 'proposal' | 'negotiation' | 'won' | 'lost'

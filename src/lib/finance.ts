import type { BillingFrequency } from './types'

export const installmentsForFrequency = (frequency: BillingFrequency) => ({
  annual: 1,
  semi_annual: 2,
  quarterly: 4,
  monthly: 12,
}[frequency])

export const frequencyLabel = (frequency?: string) => ({
  annual: 'Annually',
  semi_annual: 'Semi-Annually',
  quarterly: 'Quarterly',
  monthly: 'Monthly',
}[frequency || ''] || frequency || '—')

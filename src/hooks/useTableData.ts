import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'

export function useTableData<T = any>(table: string, select = '*', orderBy = 'created_at') {
  const [data, setData] = useState<T[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    setLoading(true)
    let query = supabase.from(table).select(select)
    if (orderBy) query = query.order(orderBy, { ascending: false })
    const { data: rows, error: e } = await query
    if (e) setError(e.message)
    else { setData((rows || []) as T[]); setError(null) }
    setLoading(false)
  }, [table, select, orderBy])

  useEffect(() => { refresh() }, [refresh])
  return { data, loading, error, refresh, setData }
}

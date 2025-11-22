'use client'

import { useState, useEffect } from 'react'
import { format, subDays, startOfWeek, addDays } from 'date-fns'
import { fr } from 'date-fns/locale'
import { Download, TrendingUp, TrendingDown, DollarSign, ShoppingCart, Trash2, Package } from 'lucide-react'
import { statsApi, inventoryApi, type StatsSummary, type DailyInventory } from '@/lib/api'
import { formatCurrency } from '@/lib/currency'
import WeekBar from '@/components/WeekBar'

export default function StatistiquesPage() {
  const [stats, setStats] = useState<StatsSummary | null>(null)
  const [recentInventories, setRecentInventories] = useState<DailyInventory[]>([])
  const [loading, setLoading] = useState(true)
  const [period, setPeriod] = useState<'7' | '30' | 'all' | 'week'>('week')
  const [selectedDate, setSelectedDate] = useState(format(new Date(), 'yyyy-MM-dd'))

  useEffect(() => {
    loadStats()
  }, [period])

  const loadStats = async () => {
    try {
      setLoading(true)
      const todayStr = format(new Date(), 'yyyy-MM-dd')
      let startDate = ''
      let endDate = todayStr

      if (period === 'week') {
        const ws = startOfWeek(new Date(selectedDate), { weekStartsOn: 1, locale: fr })
        startDate = format(ws, 'yyyy-MM-dd')
        endDate = format(addDays(ws, 6), 'yyyy-MM-dd')
      } else if (period === '7') {
        startDate = format(subDays(new Date(), 7), 'yyyy-MM-dd')
      } else if (period === '30') {
        startDate = format(subDays(new Date(), 30), 'yyyy-MM-dd')
      } else {
        startDate = ''
        endDate = todayStr
      }

      const params = period !== 'all' ? { startDate, endDate } : {}

      const [statsRes, inventoriesRes] = await Promise.all([
        statsApi.getSummary(params.startDate, params.endDate),
        inventoryApi.getAll(10),
      ])

      setStats(statsRes.data)
      setRecentInventories(inventoriesRes.data)
    } catch (error) {
      console.error('Error loading stats:', error)
      alert('Impossible de charger les statistiques')
    } finally {
      setLoading(false)
    }
  }

  const handleExport = async () => {
    try {
      const todayStr = format(new Date(), 'yyyy-MM-dd')
      let startDate = ''
      let endDate = todayStr

      if (period === 'week') {
        const ws = startOfWeek(new Date(selectedDate), { weekStartsOn: 1, locale: fr })
        startDate = format(ws, 'yyyy-MM-dd')
        endDate = format(addDays(ws, 6), 'yyyy-MM-dd')
      } else if (period === '7') {
        startDate = format(subDays(new Date(), 7), 'yyyy-MM-dd')
      } else if (period === '30') {
        startDate = format(subDays(new Date(), 30), 'yyyy-MM-dd')
      }

      const response = await statsApi.export(startDate || undefined, endDate)
      const blob = new Blob([JSON.stringify(response.data, null, 2)], { type: 'application/json' })
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `export-patisserie-${today}.json`
      a.click()
      window.URL.revokeObjectURL(url)
      alert('Export réussi !')
    } catch (error) {
      console.error('Error exporting data:', error)
      alert('Impossible d\'exporter les données')
    }
  }

  const getWastePercentage = (wasted: number, produced: number) => {
    if (produced === 0) return 0
    return ((wasted / produced) * 100).toFixed(1)
  }

  const getSoldPercentage = (sold: number, produced: number) => {
    if (produced === 0) return 0
    return ((sold / produced) * 100).toFixed(1)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-slate-600">Chargement...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header + Week bar */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4">
          <div>
            <h1 className="text-2xl md:text-3xl font-bold text-slate-900 mb-2">Statistiques</h1>
            <p className="text-slate-600">Analysez vos performances</p>
          </div>
          <button onClick={handleExport} className="btn-secondary w-full sm:w-auto">
            <Download size={20} className="inline mr-2" />
            Exporter
          </button>
        </div>
        <WeekBar
          date={selectedDate}
          onChange={(d) => {
            setSelectedDate(d)
            setPeriod('week')
          }}
          title="Semaine"
        />

        {/* Period Selector */}
        <div className="flex flex-wrap gap-2 md:gap-3 mb-6 md:mb-8">
          {[
            { value: 'week', label: 'Semaine' },
            { value: '7', label: '7 jours' },
            { value: '30', label: '30 jours' },
            { value: 'all', label: 'Tout' },
          ].map((item) => (
            <button
              key={item.value}
              onClick={() => setPeriod(item.value as any)}
              className={`px-4 md:px-6 py-2 rounded-lg font-medium transition-all text-sm md:text-base ${
                period === item.value
                  ? 'bg-primary text-white shadow-md'
                  : 'bg-white text-slate-700 hover:bg-slate-50 border border-slate-200'
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>

        {stats && (
          <>
            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              <div className="card border-t-4 border-t-success">
                <div className="flex items-center justify-between mb-4">
                  <div className="p-3 bg-green-100 rounded-lg">
                    <DollarSign size={24} className="text-success" />
                  </div>
                  <TrendingUp size={20} className="text-success" />
                </div>
                <p className="text-sm text-slate-600 mb-1">Chiffre d'affaires</p>
                <p className="text-3xl font-bold text-slate-900">{formatCurrency(stats.total_sales)}</p>
              </div>

              <div className="card border-t-4 border-t-primary">
                <div className="flex items-center justify-between mb-4">
                  <div className="p-3 bg-blue-100 rounded-lg">
                    <ShoppingCart size={24} className="text-primary" />
                  </div>
                  <TrendingUp size={20} className="text-primary" />
                </div>
                <p className="text-sm text-slate-600 mb-1">Produits vendus</p>
                <p className="text-3xl font-bold text-slate-900">{stats.total_sold}</p>
              </div>

              <div className="card border-t-4 border-t-danger">
                <div className="flex items-center justify-between mb-4">
                  <div className="p-3 bg-red-100 rounded-lg">
                    <Trash2 size={24} className="text-danger" />
                  </div>
                  <TrendingDown size={20} className="text-danger" />
                </div>
                <p className="text-sm text-slate-600 mb-1">Produits jetés</p>
                <p className="text-3xl font-bold text-slate-900">{stats.total_wasted}</p>
              </div>

              <div className="card border-t-4 border-t-warning">
                <div className="flex items-center justify-between mb-4">
                  <div className="p-3 bg-orange-100 rounded-lg">
                    <Package size={24} className="text-warning" />
                  </div>
                </div>
                <p className="text-sm text-slate-600 mb-1">Produits fabriqués</p>
                <p className="text-3xl font-bold text-slate-900">{stats.total_produced}</p>
              </div>
            </div>

            {/* Products Performance */}
            <div className="mb-8">
              <h2 className="text-2xl font-bold text-slate-900 mb-4">Performance par produit</h2>
              {stats.products_stats.length === 0 ? (
                <div className="card text-center py-12">
                  <p className="text-slate-600">Aucune donnée disponible</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {stats.products_stats.map((product) => (
                    <div key={product.product_id} className="card">
                      <div className="flex items-center justify-between mb-4">
                        <div>
                          <h3 className="text-lg font-semibold text-slate-900">{product.product_name}</h3>
                          <p className="text-sm text-slate-600 capitalize">{product.category}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-2xl font-bold text-success">{formatCurrency(product.total_revenue)}</p>
                          <p className="text-sm text-slate-600">Revenu total</p>
                        </div>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-4">
                        <div className="text-center">
                          <p className="text-sm text-slate-600 mb-1">Moyenne/jour</p>
                          <p className="text-xl font-bold text-slate-900">{product.avg_sold_per_day}</p>
                        </div>
                        <div className="text-center">
                          <p className="text-sm text-slate-600 mb-1">Taux de vente</p>
                        <p className="text-xl font-bold text-success">
                            {getSoldPercentage(product.total_sold, product.total_produced)}%
                          </p>
                        </div>
                        <div className="text-center">
                          <p className="text-sm text-slate-600 mb-1">Gaspillage</p>
                        <p className="text-xl font-bold text-danger">
                            {getWastePercentage(product.total_wasted, product.total_produced)}%
                          </p>
                        </div>
                      </div>

                      {/* Progress Bar */}
                      <div className="h-3 bg-slate-100 rounded-full overflow-hidden flex">
                        <div
                          className="bg-success h-full"
                          style={{
                            width: `${getSoldPercentage(product.total_sold, product.total_produced)}%`,
                          }}
                        />
                        <div
                          className="bg-danger h-full"
                          style={{
                            width: `${getWastePercentage(product.total_wasted, product.total_produced)}%`,
                          }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Recent Inventories */}
            <div>
              <h2 className="text-2xl font-bold text-slate-900 mb-4">Historique récent</h2>
              {recentInventories.length === 0 ? (
                <div className="card text-center py-12">
                  <p className="text-slate-600">Aucun inventaire</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {recentInventories.map((inventory) => (
                    <div key={inventory.id} className="card hover:shadow-md transition-shadow">
                      <div className="flex items-center justify-between mb-3">
                        <p className="text-sm font-medium text-slate-600">
                          {format(new Date(inventory.date), 'dd MMM yyyy', { locale: fr })}
                        </p>
                        <p className="text-xl font-bold text-success">
                          {formatCurrency(inventory.total_revenue)}
                        </p>
                      </div>
                      <p className="text-sm text-slate-600">{inventory.products.length} produit(s)</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  )
}

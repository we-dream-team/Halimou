'use client'

import { useState, useEffect, useRef } from 'react'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import { Calendar, Plus, Minus, Save, Settings, Package } from 'lucide-react'
import { productApi, inventoryApi, type Product, type InventoryProduct, type DailyInventory } from '@/lib/api'
import { formatCurrency } from '@/lib/currency'
import WeekBar from '@/components/WeekBar'

export default function InventairePage() {
  const [selectedDate, setSelectedDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [products, setProducts] = useState<Product[]>([])
  const [inventory, setInventory] = useState<DailyInventory | null>(null)
  const [inventoryProducts, setInventoryProducts] = useState<InventoryProduct[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [showProductModal, setShowProductModal] = useState(false)
  const [selectedProductIds, setSelectedProductIds] = useState<Set<string>>(new Set())
  const [saveMessage, setSaveMessage] = useState<string>('')
  const saveTimeoutRef = useRef<NodeJS.Timeout | null>(null)
  const lastSavedHashRef = useRef<string>('')
  const [showReintegrateModal, setShowReintegrateModal] = useState(false)
  const [prevDayItems, setPrevDayItems] = useState<Array<{ product_id: string; product_name: string; remaining: number; addQuantity: number; price: number; category: string }>>([])
  const [loadingPrev, setLoadingPrev] = useState(false)
  const [hasReintegrated, setHasReintegrated] = useState(false)

  useEffect(() => {
    loadData()
    // nouvelle date => on autorise une nouvelle réintégration
    setHasReintegrated(false)
  }, [selectedDate])

  const loadData = async () => {
    try {
      setLoading(true)
      const productsRes = await productApi.getAll()
      setProducts(productsRes.data)

      try {
        const inventoryRes = await inventoryApi.getByDate(selectedDate)
        setInventory(inventoryRes.data)
        setInventoryProducts(inventoryRes.data.products)
      } catch (error: any) {
        if (error.response?.status === 404) {
          setInventory(null)
          setInventoryProducts([])
        }
      }
    } catch (error) {
      console.error('Error loading data:', error)
      alert('Erreur lors du chargement des données')
    } finally {
      setLoading(false)
    }
  }

  const handleOpenProductModal = () => {
    setSelectedProductIds(new Set(inventoryProducts.map(p => p.product_id)))
    setShowProductModal(true)
  }

  const handleConfirmProducts = () => {
    const newInventoryProducts: InventoryProduct[] = []
    
    selectedProductIds.forEach(productId => {
      const existing = inventoryProducts.find(p => p.product_id === productId)
      if (existing) {
        newInventoryProducts.push(existing)
      } else {
        const product = products.find(p => p.id === productId)
        if (product) {
          newInventoryProducts.push({
            product_id: product.id,
            product_name: product.name,
            category: product.category,
            quantity_produced: 0,
            quantity_sold: 0,
            quantity_wasted: 0,
            quantity_remaining: 0,
            price: product.price,
          })
        }
      }
    })

    setInventoryProducts(newInventoryProducts)
    setShowProductModal(false)
  }

  const updateQuantity = (productId: string, field: keyof InventoryProduct, value: number) => {
    setInventoryProducts(prev => {
      return prev.map(p => {
        if (p.product_id === productId) {
          const updated = { ...p, [field]: Math.max(0, value) }
          if (field !== 'quantity_remaining') {
            updated.quantity_remaining = Math.max(
              0,
              updated.quantity_produced - updated.quantity_sold - updated.quantity_wasted
            )
          }
          return updated
        }
        return p
      })
    })
  }

  // Autosave: déclenche un enregistrement après une inactivité brève
  useEffect(() => {
    // Ne pas autosave pendant le chargement initial
    if (loading) return
    // Hash simple pour éviter les sauvegardes inutiles
    const hash = JSON.stringify(inventoryProducts)
    if (hash === lastSavedHashRef.current) return

    // Nettoyer le timer précédent
    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current)
    }

    // Déclencher une sauvegarde après 800ms d'inactivité
    saveTimeoutRef.current = setTimeout(async () => {
      if (inventoryProducts.length === 0) {
        return
      }
      try {
        setSaving(true)
        setSaveMessage('Enregistrement…')
        const payload = { products: inventoryProducts }
        if (inventory) {
          await inventoryApi.update(selectedDate, payload)
        } else {
          await inventoryApi.create({ date: selectedDate, products: inventoryProducts })
        }
        lastSavedHashRef.current = hash
        setSaveMessage('Enregistré')
        // Effacer le message après 1.5s
        setTimeout(() => setSaveMessage(''), 1500)
      } catch (error: any) {
        console.error('Error saving inventory:', error)
        setSaveMessage(error?.response?.data?.detail || 'Erreur sauvegarde')
      } finally {
        setSaving(false)
      }
    }, 800)

    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [inventoryProducts, selectedDate, inventory, loading])

  const totalRevenue = inventoryProducts.reduce((sum, p) => sum + p.quantity_sold * p.price, 0)

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
      <div className="max-w-6xl mx-auto">
        {/* Header + Week bar */}
        <div className="mb-4">
          <h1 className="text-2xl md:text-3xl font-bold text-slate-900 mb-2">Inventaire</h1>
          <WeekBar
            date={selectedDate}
            onChange={(d) => setSelectedDate(d)}
            title="Semaine"
          />
          <div className="flex items-center justify-end mt-4">
            <button
              onClick={async () => {
                if (hasReintegrated) return
                const prevDate = format(new Date(new Date(selectedDate).getTime() - 24 * 60 * 60 * 1000), 'yyyy-MM-dd')
                try {
                  setLoadingPrev(true)
                  const prev = await inventoryApi.getByDate(prevDate)
                  const prevProducts = (prev.data.products || []).filter((p) => (p.quantity_remaining || 0) > 0)
                  const items = prevProducts.map((p) => ({
                    product_id: p.product_id,
                    product_name: p.product_name,
                    remaining: p.quantity_remaining || 0,
                    addQuantity: p.quantity_remaining || 0,
                    price: p.price,
                    category: p.category,
                  }))
                  setPrevDayItems(items)
                  setShowReintegrateModal(true)
                } catch (e) {
                  console.error('Impossible d\'importer les invendus de la veille', e)
                  alert('Aucun inventaire de la veille trouvé ou erreur réseau')
                } finally {
                  setLoadingPrev(false)
                }
              }}
              className={`btn-secondary text-sm md:text-base ${hasReintegrated ? 'opacity-60 cursor-not-allowed' : ''}`}
              disabled={hasReintegrated || loadingPrev}
            >
              {hasReintegrated ? 'Déjà réintégré' : (loadingPrev ? 'Chargement…' : <><span className="hidden sm:inline">Réintégrer les invendus de la veille</span><span className="sm:hidden">Réintégrer</span></>)}
            </button>
          </div>
        </div>

        {/* Empty State */}
        {inventoryProducts.length === 0 ? (
          <div className="card text-center py-16">
            <div className="text-slate-400 mb-4">
              <Package size={64} className="mx-auto" />
            </div>
            <h3 className="text-xl font-semibold text-slate-700 mb-2">Aucun produit ajouté</h3>
            <p className="text-slate-600 mb-6">Commencez par ajouter des produits à votre inventaire</p>
            <button onClick={handleOpenProductModal} className="btn-primary">
              <Settings size={20} className="inline mr-2" />
              Gérer les produits
            </button>
          </div>
        ) : (
          <>
            {/* Products List */}
            <div className="space-y-4 mb-6">
              {inventoryProducts.map((product) => (
                <div key={product.product_id} className="card">
                  <div className="flex items-center justify-between mb-4">
                    <div>
                      <h3 className="text-lg font-semibold text-slate-900">{product.product_name}</h3>
                      <p className="text-sm text-slate-600">{product.category} • {formatCurrency(product.price)}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
                    <div>
                      <label className="block text-xs md:text-sm font-medium text-slate-700 mb-2">Produit</label>
                      <div className="flex items-center space-x-1 md:space-x-2">
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_produced', product.quantity_produced - 1)}
                          className="p-1.5 md:p-2 rounded-lg bg-slate-100 hover:bg-slate-200 transition-colors touch-manipulation"
                          aria-label="Diminuer"
                        >
                          <Minus size={14} className="md:w-4 md:h-4" />
                        </button>
                        <input
                          type="number"
                          value={product.quantity_produced}
                          onChange={(e) => updateQuantity(product.product_id, 'quantity_produced', parseInt(e.target.value) || 0)}
                          className="input text-center flex-1 min-w-0"
                        />
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_produced', product.quantity_produced + 1)}
                          className="p-1.5 md:p-2 rounded-lg bg-slate-100 hover:bg-slate-200 transition-colors touch-manipulation"
                          aria-label="Augmenter"
                        >
                          <Plus size={14} className="md:w-4 md:h-4" />
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs md:text-sm font-medium text-slate-700 mb-2">Vendu</label>
                      <div className="flex items-center space-x-1 md:space-x-2">
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_sold', product.quantity_sold - 1)}
                          className="p-1.5 md:p-2 rounded-lg bg-green-100 hover:bg-green-200 transition-colors text-green-700 touch-manipulation"
                          aria-label="Diminuer"
                        >
                          <Minus size={14} className="md:w-4 md:h-4" />
                        </button>
                        <input
                          type="number"
                          value={product.quantity_sold}
                          onChange={(e) => updateQuantity(product.product_id, 'quantity_sold', parseInt(e.target.value) || 0)}
                          className="input text-center flex-1 min-w-0"
                        />
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_sold', product.quantity_sold + 1)}
                          className="p-1.5 md:p-2 rounded-lg bg-green-100 hover:bg-green-200 transition-colors text-green-700 touch-manipulation"
                          aria-label="Augmenter"
                        >
                          <Plus size={14} className="md:w-4 md:h-4" />
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs md:text-sm font-medium text-slate-700 mb-2">Jeté</label>
                      <div className="flex items-center space-x-1 md:space-x-2">
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_wasted', product.quantity_wasted - 1)}
                          className="p-1.5 md:p-2 rounded-lg bg-red-100 hover:bg-red-200 transition-colors text-red-700 touch-manipulation"
                          aria-label="Diminuer"
                        >
                          <Minus size={14} className="md:w-4 md:h-4" />
                        </button>
                        <input
                          type="number"
                          value={product.quantity_wasted}
                          onChange={(e) => updateQuantity(product.product_id, 'quantity_wasted', parseInt(e.target.value) || 0)}
                          className="input text-center flex-1 min-w-0"
                        />
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_wasted', product.quantity_wasted + 1)}
                          className="p-1.5 md:p-2 rounded-lg bg-red-100 hover:bg-red-200 transition-colors text-red-700 touch-manipulation"
                          aria-label="Augmenter"
                        >
                          <Plus size={14} className="md:w-4 md:h-4" />
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs md:text-sm font-medium text-slate-700 mb-2">Restant</label>
                      <div className="input bg-slate-50 text-center font-semibold text-slate-900 py-2">
                        {product.quantity_remaining}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Summary */}
            <div className="card bg-primary text-white mb-6">
              <h3 className="text-lg md:text-xl font-bold mb-2">Résumé du jour</h3>
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                <span className="text-blue-100">Chiffre d'affaires</span>
                <span className="text-2xl md:text-3xl font-bold">{formatCurrency(totalRevenue)}</span>
              </div>
              <div className="mt-2 text-xs md:text-sm text-blue-100">
                {saving ? 'Enregistrement automatique…' : saveMessage}
              </div>
            </div>

            {/* Actions */}
            <div className="flex space-x-4">
              <button onClick={handleOpenProductModal} className="btn-secondary flex-1">
                <Settings size={18} className="inline mr-2" />
                <span className="hidden sm:inline">Gérer les produits</span>
                <span className="sm:hidden">Produits</span>
              </button>
            </div>
          </>
        )}

        {/* Product Selection Modal */}
        {showProductModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50 overflow-y-auto">
            <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] flex flex-col my-4">
              <div className="p-6 border-b border-slate-200">
                <h2 className="text-2xl font-bold text-slate-900">Sélectionner les produits</h2>
              </div>

              <div className="flex-1 overflow-y-auto p-6">
                <div className="space-y-2">
                  {products.map((product) => (
                    <div
                      key={product.id}
                      onClick={() => {
                        const newSelected = new Set(selectedProductIds)
                        if (newSelected.has(product.id)) {
                          newSelected.delete(product.id)
                        } else {
                          newSelected.add(product.id)
                        }
                        setSelectedProductIds(newSelected)
                      }}
                      className={`p-4 rounded-lg border-2 cursor-pointer transition-all ${
                        selectedProductIds.has(product.id)
                          ? 'border-primary bg-blue-50'
                          : 'border-slate-200 hover:border-slate-300'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <h3 className="font-semibold text-slate-900">{product.name}</h3>
                          <p className="text-sm text-slate-600">
                            {product.category} • {formatCurrency(product.price)}
                          </p>
                        </div>
                        <div
                          className={`w-6 h-6 rounded-full border-2 flex items-center justify-center ${
                            selectedProductIds.has(product.id)
                              ? 'border-primary bg-primary'
                              : 'border-slate-300'
                          }`}
                        >
                          {selectedProductIds.has(product.id) && (
                            <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                              <path d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" />
                            </svg>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="p-6 border-t border-slate-200 flex space-x-4">
                <button onClick={() => setShowProductModal(false)} className="btn-secondary flex-1">
                  Annuler
                </button>
                <button onClick={handleConfirmProducts} className="btn-primary flex-1">
                  Confirmer
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Reintegrate Modal */}
        {showReintegrateModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50 overflow-y-auto">
            <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] flex flex-col my-4">
              <div className="p-6 border-b border-slate-200">
                <h2 className="text-2xl font-bold text-slate-900">Réintégrer les invendus de la veille</h2>
                <p className="text-slate-600 mt-1 text-sm">
                  Ajustez les quantités à ajouter à la production d’aujourd’hui.
                </p>
              </div>
              <div className="flex-1 overflow-y-auto p-6">
                {prevDayItems.length === 0 ? (
                  <div className="text-slate-600">Aucun invendu à réintégrer.</div>
                ) : (
                  <div className="space-y-3">
                    {prevDayItems.map((item, idx) => (
                      <div key={item.product_id} className="p-4 rounded-lg border border-slate-200 flex items-center justify-between">
                        <div>
                          <div className="font-semibold text-slate-900">{item.product_name}</div>
                          <div className="text-sm text-slate-600">
                            Restant: {item.remaining}
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <label className="text-sm text-slate-700">À ajouter</label>
                          <input
                            type="number"
                            min={0}
                            max={item.remaining}
                            value={item.addQuantity}
                            onChange={(e) => {
                              const v = Math.max(0, Math.min(item.remaining, parseInt(e.target.value || '0', 10)))
                              setPrevDayItems((prev) => {
                                const copy = [...prev]
                                copy[idx] = { ...copy[idx], addQuantity: v }
                                return copy
                              })
                            }}
                            className="input w-24 text-center"
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              <div className="p-6 border-t border-slate-200 flex space-x-4">
                <button onClick={() => setShowReintegrateModal(false)} className="btn-secondary flex-1">
                  Annuler
                </button>
                <button
                  onClick={() => {
                    setInventoryProducts((curr) => {
                      const map = new Map<string, InventoryProduct>()
                      curr.forEach((p) => map.set(p.product_id, { ...p }))
                      prevDayItems.forEach((it) => {
                        if (it.addQuantity <= 0) return
                        const existing = map.get(it.product_id)
                        if (existing) {
                          const produced = Math.max(0, existing.quantity_produced + it.addQuantity)
                          const updated: InventoryProduct = {
                            ...existing,
                            quantity_produced: produced,
                          }
                          updated.quantity_remaining = Math.max(0, produced - updated.quantity_sold - updated.quantity_wasted)
                          map.set(it.product_id, updated)
                        } else {
                          map.set(it.product_id, {
                            product_id: it.product_id,
                            product_name: it.product_name,
                            category: it.category,
                            quantity_produced: it.addQuantity,
                            quantity_sold: 0,
                            quantity_wasted: 0,
                            quantity_remaining: it.addQuantity,
                            price: it.price,
                          })
                        }
                      })
                      return Array.from(map.values())
                    })
                    setShowReintegrateModal(false)
                    setHasReintegrated(true)
                  }}
                  className="btn-primary flex-1"
                  disabled={prevDayItems.every(it => it.addQuantity <= 0)}
                >
                  Réintégrer
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

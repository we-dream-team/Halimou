'use client'

import { useState, useEffect } from 'react'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import { Calendar, Plus, Minus, Save, Settings } from 'lucide-react'
import { productApi, inventoryApi, type Product, type InventoryProduct, type DailyInventory } from '@/lib/api'

export default function InventairePage() {
  const [selectedDate, setSelectedDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [products, setProducts] = useState<Product[]>([])
  const [inventory, setInventory] = useState<DailyInventory | null>(null)
  const [inventoryProducts, setInventoryProducts] = useState<InventoryProduct[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [showProductModal, setShowProductModal] = useState(false)
  const [selectedProductIds, setSelectedProductIds] = useState<Set<string>>(new Set())

  useEffect(() => {
    loadData()
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

  const handleSave = async () => {
    if (inventoryProducts.length === 0) {
      alert('Veuillez ajouter au moins un produit')
      return
    }

    try {
      setSaving(true)
      const inventoryData = { date: selectedDate, products: inventoryProducts }

      if (inventory) {
        await inventoryApi.update(selectedDate, { products: inventoryProducts })
      } else {
        await inventoryApi.create(inventoryData)
      }

      alert('Inventaire enregistré avec succès')
      loadData()
    } catch (error: any) {
      console.error('Error saving inventory:', error)
      alert(error.response?.data?.detail || 'Impossible d\'enregistrer l\'inventaire')
    } finally {
      setSaving(false)
    }
  }

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
    <div className="p-8">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-slate-900 mb-2">Inventaire du jour</h1>
          <div className="flex items-center text-slate-600">
            <Calendar size={20} className="mr-2" />
            <span className="text-lg">
              {format(new Date(selectedDate), 'dd MMMM yyyy', { locale: fr })}
            </span>
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
                      <p className="text-sm text-slate-600">{product.category} • {product.price.toFixed(2)} €</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">Produit</label>
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_produced', product.quantity_produced - 1)}
                          className="p-2 rounded-lg bg-slate-100 hover:bg-slate-200 transition-colors"
                        >
                          <Minus size={16} />
                        </button>
                        <input
                          type="number"
                          value={product.quantity_produced}
                          onChange={(e) => updateQuantity(product.product_id, 'quantity_produced', parseInt(e.target.value) || 0)}
                          className="input text-center"
                        />
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_produced', product.quantity_produced + 1)}
                          className="p-2 rounded-lg bg-slate-100 hover:bg-slate-200 transition-colors"
                        >
                          <Plus size={16} />
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">Vendu</label>
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_sold', product.quantity_sold - 1)}
                          className="p-2 rounded-lg bg-green-100 hover:bg-green-200 transition-colors text-green-700"
                        >
                          <Minus size={16} />
                        </button>
                        <input
                          type="number"
                          value={product.quantity_sold}
                          onChange={(e) => updateQuantity(product.product_id, 'quantity_sold', parseInt(e.target.value) || 0)}
                          className="input text-center"
                        />
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_sold', product.quantity_sold + 1)}
                          className="p-2 rounded-lg bg-green-100 hover:bg-green-200 transition-colors text-green-700"
                        >
                          <Plus size={16} />
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">Jeté</label>
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_wasted', product.quantity_wasted - 1)}
                          className="p-2 rounded-lg bg-red-100 hover:bg-red-200 transition-colors text-red-700"
                        >
                          <Minus size={16} />
                        </button>
                        <input
                          type="number"
                          value={product.quantity_wasted}
                          onChange={(e) => updateQuantity(product.product_id, 'quantity_wasted', parseInt(e.target.value) || 0)}
                          className="input text-center"
                        />
                        <button
                          onClick={() => updateQuantity(product.product_id, 'quantity_wasted', product.quantity_wasted + 1)}
                          className="p-2 rounded-lg bg-red-100 hover:bg-red-200 transition-colors text-red-700"
                        >
                          <Plus size={16} />
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">Restant</label>
                      <div className="input bg-slate-50 text-center font-semibold text-slate-900">
                        {product.quantity_remaining}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Summary */}
            <div className="card bg-primary text-white mb-6">
              <h3 className="text-xl font-bold mb-2">Résumé du jour</h3>
              <div className="flex items-center justify-between">
                <span className="text-blue-100">Chiffre d'affaires</span>
                <span className="text-3xl font-bold">{totalRevenue.toFixed(2)} €</span>
              </div>
            </div>

            {/* Actions */}
            <div className="flex space-x-4">
              <button onClick={handleOpenProductModal} className="btn-secondary flex-1">
                <Settings size={20} className="inline mr-2" />
                Gérer les produits
              </button>
              <button 
                onClick={handleSave} 
                disabled={saving}
                className="btn-primary flex-1"
              >
                {saving ? (
                  <span>Enregistrement...</span>
                ) : (
                  <>
                    <Save size={20} className="inline mr-2" />
                    Enregistrer
                  </>
                )}
              </button>
            </div>
          </>
        )}

        {/* Product Selection Modal */}
        {showProductModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-xl max-w-2xl w-full max-h-[80vh] flex flex-col">
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
                            {product.category} • {product.price.toFixed(2)} €
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
      </div>
    </div>
  )
}

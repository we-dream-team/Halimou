'use client'

import { useState, useEffect } from 'react'
import { Plus, Pencil, Trash2, Package } from 'lucide-react'
import { productApi, type Product } from '@/lib/api'

export default function ProduitsPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingProduct, setEditingProduct] = useState<Product | null>(null)
  const [formData, setFormData] = useState({
    name: '',
    category: 'viennoiserie',
    price: '',
    is_recurring: true,
  })

  useEffect(() => {
    loadProducts()
  }, [])

  const loadProducts = async () => {
    try {
      setLoading(true)
      const response = await productApi.getAll()
      setProducts(response.data)
    } catch (error) {
      console.error('Error loading products:', error)
      alert('Impossible de charger les produits')
    } finally {
      setLoading(false)
    }
  }

  const handleOpenModal = (product?: Product) => {
    if (product) {
      setEditingProduct(product)
      setFormData({
        name: product.name,
        category: product.category,
        price: product.price.toString(),
        is_recurring: product.is_recurring,
      })
    } else {
      setEditingProduct(null)
      setFormData({
        name: '',
        category: 'viennoiserie',
        price: '',
        is_recurring: true,
      })
    }
    setShowModal(true)
  }

  const handleSave = async () => {
    if (!formData.name.trim()) {
      alert('Le nom du produit est requis')
      return
    }

    const price = parseFloat(formData.price)
    if (isNaN(price) || price <= 0) {
      alert('Le prix doit être un nombre valide')
      return
    }

    try {
      const productData = {
        name: formData.name.trim(),
        category: formData.category,
        price: price,
        is_recurring: formData.is_recurring,
      }

      if (editingProduct) {
        await productApi.update(editingProduct.id, productData)
        alert('Produit mis à jour')
      } else {
        await productApi.create(productData)
        alert('Produit ajouté')
      }

      setShowModal(false)
      loadProducts()
    } catch (error: any) {
      console.error('Error saving product:', error)
      alert(error.response?.data?.detail || 'Impossible de sauvegarder le produit')
    }
  }

  const handleDelete = async (product: Product) => {
    if (!confirm(`Êtes-vous sûr de vouloir supprimer "${product.name}" ?`)) {
      return
    }

    try {
      await productApi.delete(product.id)
      alert('Produit supprimé')
      loadProducts()
    } catch (error: any) {
      console.error('Error deleting product:', error)
      alert('Impossible de supprimer le produit')
    }
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
    <div className="p-8">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 mb-2">Catalogue Produits</h1>
            <p className="text-slate-600">{products.length} produit(s)</p>
          </div>
          <button onClick={() => handleOpenModal()} className="btn-primary">
            <Plus size={20} className="inline mr-2" />
            Ajouter un produit
          </button>
        </div>

        {/* Products Grid */}
        {products.length === 0 ? (
          <div className="card text-center py-16">
            <div className="text-slate-400 mb-4">
              <Package size={64} className="mx-auto" />
            </div>
            <h3 className="text-xl font-semibold text-slate-700 mb-2">Aucun produit</h3>
            <p className="text-slate-600 mb-6">Ajoutez votre premier produit pour commencer</p>
            <button onClick={() => handleOpenModal()} className="btn-primary">
              <Plus size={20} className="inline mr-2" />
              Ajouter un produit
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {products.map((product) => (
              <div key={product.id} className="card hover:shadow-md transition-shadow">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-slate-900 mb-1">{product.name}</h3>
                    <p className="text-sm text-slate-600 capitalize mb-2">{product.category}</p>
                    <p className="text-xl font-bold text-success">{product.price.toFixed(2)} €</p>
                  </div>
                  <div className="flex space-x-2">
                    <button
                      onClick={() => handleOpenModal(product)}
                      className="p-2 text-primary hover:bg-blue-50 rounded-lg transition-colors"
                    >
                      <Pencil size={18} />
                    </button>
                    <button
                      onClick={() => handleDelete(product)}
                      className="p-2 text-danger hover:bg-red-50 rounded-lg transition-colors"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                </div>
                {product.is_recurring && (
                  <span className="inline-block px-3 py-1 bg-blue-100 text-primary text-xs font-semibold rounded-full">
                    Récurrent
                  </span>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Modal */}
        {showModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-xl max-w-lg w-full">
              <div className="p-6 border-b border-slate-200">
                <h2 className="text-2xl font-bold text-slate-900">
                  {editingProduct ? 'Modifier le produit' : 'Nouveau produit'}
                </h2>
              </div>

              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Nom du produit</label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="Ex: Croissant"
                    className="input"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Catégorie</label>
                  <div className="grid grid-cols-3 gap-2">
                    {['viennoiserie', 'gâteau', 'autre'].map((cat) => (
                      <button
                        key={cat}
                        onClick={() => setFormData({ ...formData, category: cat })}
                        className={`py-2 px-4 rounded-lg font-medium transition-all ${
                          formData.category === cat
                            ? 'bg-primary text-white'
                            : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                        }`}
                      >
                        {cat.charAt(0).toUpperCase() + cat.slice(1)}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Prix (€)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={formData.price}
                    onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                    placeholder="Ex: 1.50"
                    className="input"
                  />
                </div>

                <div className="flex items-center space-x-3">
                  <input
                    type="checkbox"
                    id="recurring"
                    checked={formData.is_recurring}
                    onChange={(e) => setFormData({ ...formData, is_recurring: e.target.checked })}
                    className="w-5 h-5 text-primary rounded focus:ring-2 focus:ring-primary"
                  />
                  <label htmlFor="recurring" className="text-sm font-medium text-slate-700">
                    Produit récurrent (apparaît automatiquement dans les inventaires)
                  </label>
                </div>
              </div>

              <div className="p-6 border-t border-slate-200 flex space-x-4">
                <button onClick={() => setShowModal(false)} className="btn-secondary flex-1">
                  Annuler
                </button>
                <button onClick={handleSave} className="btn-primary flex-1">
                  {editingProduct ? 'Modifier' : 'Ajouter'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

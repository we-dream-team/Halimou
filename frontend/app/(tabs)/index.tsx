import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  TextInput,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import Modal from 'react-native-modal';
import axios from 'axios';

const API_URL = process.env.EXPO_PUBLIC_BACKEND_URL;

interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  is_recurring: boolean;
}

interface InventoryProduct {
  product_id: string;
  product_name: string;
  category: string;
  quantity_produced: number;
  quantity_sold: number;
  quantity_wasted: number;
  quantity_remaining: number;
  price: number;
}

interface DailyInventory {
  id?: string;
  date: string;
  products: InventoryProduct[];
  total_revenue: number;
}

export default function InventoryScreen() {
  const [selectedDate, setSelectedDate] = useState<string>(format(new Date(), 'yyyy-MM-dd'));
  const [products, setProducts] = useState<Product[]>([]);
  const [inventory, setInventory] = useState<DailyInventory | null>(null);
  const [inventoryProducts, setInventoryProducts] = useState<InventoryProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [selectedProducts, setSelectedProducts] = useState<Set<string>>(new Set());

  useEffect(() => {
    loadData();
  }, [selectedDate]);

  const loadData = async () => {
    try {
      setLoading(true);
      
      // Load products
      const productsRes = await axios.get(`${API_URL}/api/products`);
      setProducts(productsRes.data);

      // Try to load existing inventory for the date
      try {
        const inventoryRes = await axios.get(`${API_URL}/api/inventories/${selectedDate}`);
        setInventory(inventoryRes.data);
        setInventoryProducts(inventoryRes.data.products);
      } catch (error: any) {
        if (error.response?.status === 404) {
          // No inventory for this date
          setInventory(null);
          setInventoryProducts([]);
        }
      }
    } catch (error) {
      console.error('Error loading data:', error);
      Alert.alert('Erreur', 'Impossible de charger les données');
    } finally {
      setLoading(false);
    }
  };

  const handleAddProducts = () => {
    setSelectedProducts(new Set(inventoryProducts.map(p => p.product_id)));
    setIsModalVisible(true);
  };

  const handleConfirmProducts = () => {
    const newInventoryProducts: InventoryProduct[] = [];
    
    selectedProducts.forEach(productId => {
      const existing = inventoryProducts.find(p => p.product_id === productId);
      if (existing) {
        newInventoryProducts.push(existing);
      } else {
        const product = products.find(p => p.id === productId);
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
          });
        }
      }
    });

    setInventoryProducts(newInventoryProducts);
    setIsModalVisible(false);
  };

  const toggleProductSelection = (productId: string) => {
    const newSelected = new Set(selectedProducts);
    if (newSelected.has(productId)) {
      newSelected.delete(productId);
    } else {
      newSelected.add(productId);
    }
    setSelectedProducts(newSelected);
  };

  const updateProductQuantity = (productId: string, field: keyof InventoryProduct, value: number) => {
    setInventoryProducts(prev => {
      return prev.map(p => {
        if (p.product_id === productId) {
          const updated = { ...p, [field]: Math.max(0, value) };
          // Auto-calculate remaining
          if (field !== 'quantity_remaining') {
            updated.quantity_remaining = Math.max(
              0,
              updated.quantity_produced - updated.quantity_sold - updated.quantity_wasted
            );
          }
          return updated;
        }
        return p;
      });
    });
  };

  const handleSave = async () => {
    if (inventoryProducts.length === 0) {
      Alert.alert('Attention', 'Veuillez ajouter au moins un produit');
      return;
    }

    try {
      setSaving(true);
      
      const inventoryData = {
        date: selectedDate,
        products: inventoryProducts,
      };

      if (inventory) {
        // Update existing
        await axios.put(`${API_URL}/api/inventories/${selectedDate}`, { products: inventoryProducts });
      } else {
        // Create new
        await axios.post(`${API_URL}/api/inventories`, inventoryData);
      }

      Alert.alert('Succès', 'Inventaire enregistré avec succès');
      loadData();
    } catch (error: any) {
      console.error('Error saving inventory:', error);
      Alert.alert('Erreur', error.response?.data?.detail || 'Impossible d\'enregistrer l\'inventaire');
    } finally {
      setSaving(false);
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'viennoiserie':
        return 'cafe-outline';
      case 'gâteau':
        return 'ice-cream-outline';
      default:
        return 'pizza-outline';
    }
  };

  const totalRevenue = inventoryProducts.reduce(
    (sum, p) => sum + p.quantity_sold * p.price,
    0
  );

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#4A90E2" />
          <Text style={styles.loadingText}>Chargement...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={{ flex: 1 }}
      >
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Inventaire du jour</Text>
          <View style={styles.dateContainer}>
            <Ionicons name="calendar-outline" size={20} color="#64748B" />
            <Text style={styles.dateText}>
              {format(new Date(selectedDate), 'dd MMMM yyyy', { locale: fr })}
            </Text>
          </View>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {inventoryProducts.length === 0 ? (
            <View style={styles.emptyState}>
              <Ionicons name="basket-outline" size={64} color="#CBD5E1" />
              <Text style={styles.emptyStateText}>Aucun produit ajouté</Text>
              <Text style={styles.emptyStateSubtext}>Commencez par ajouter des produits à votre inventaire</Text>
            </View>
          ) : (
            <>
              {inventoryProducts.map((product, index) => (
                <View key={`${product.product_id}-${index}`} style={styles.productCard}>
                  <View style={styles.productHeader}>
                    <View style={styles.productInfo}>
                      <Ionicons
                        name={getCategoryIcon(product.category)}
                        size={24}
                        color="#4A90E2"
                        style={styles.productIcon}
                      />
                      <View>
                        <Text style={styles.productName}>{product.product_name}</Text>
                        <Text style={styles.productCategory}>{product.category}</Text>
                        <Text style={styles.productPrice}>{product.price.toFixed(2)} €</Text>
                      </View>
                    </View>
                  </View>

                  <View style={styles.quantityRow}>
                    <View style={styles.quantityItem}>
                      <Text style={styles.quantityLabel}>Produit</Text>
                      <View style={styles.quantityControl}>
                        <TouchableOpacity
                          style={styles.quantityButton}
                          onPress={() => updateProductQuantity(product.product_id, 'quantity_produced', product.quantity_produced - 1)}
                        >
                          <Ionicons name="remove" size={20} color="#4A90E2" />
                        </TouchableOpacity>
                        <TextInput
                          style={styles.quantityInput}
                          value={product.quantity_produced.toString()}
                          onChangeText={(text) => updateProductQuantity(product.product_id, 'quantity_produced', parseInt(text) || 0)}
                          keyboardType="numeric"
                        />
                        <TouchableOpacity
                          style={styles.quantityButton}
                          onPress={() => updateProductQuantity(product.product_id, 'quantity_produced', product.quantity_produced + 1)}
                        >
                          <Ionicons name="add" size={20} color="#4A90E2" />
                        </TouchableOpacity>
                      </View>
                    </View>

                    <View style={styles.quantityItem}>
                      <Text style={styles.quantityLabel}>Vendu</Text>
                      <View style={styles.quantityControl}>
                        <TouchableOpacity
                          style={styles.quantityButton}
                          onPress={() => updateProductQuantity(product.product_id, 'quantity_sold', product.quantity_sold - 1)}
                        >
                          <Ionicons name="remove" size={20} color="#10B981" />
                        </TouchableOpacity>
                        <TextInput
                          style={styles.quantityInput}
                          value={product.quantity_sold.toString()}
                          onChangeText={(text) => updateProductQuantity(product.product_id, 'quantity_sold', parseInt(text) || 0)}
                          keyboardType="numeric"
                        />
                        <TouchableOpacity
                          style={styles.quantityButton}
                          onPress={() => updateProductQuantity(product.product_id, 'quantity_sold', product.quantity_sold + 1)}
                        >
                          <Ionicons name="add" size={20} color="#10B981" />
                        </TouchableOpacity>
                      </View>
                    </View>
                  </View>

                  <View style={styles.quantityRow}>
                    <View style={styles.quantityItem}>
                      <Text style={styles.quantityLabel}>Jeté</Text>
                      <View style={styles.quantityControl}>
                        <TouchableOpacity
                          style={styles.quantityButton}
                          onPress={() => updateProductQuantity(product.product_id, 'quantity_wasted', product.quantity_wasted - 1)}
                        >
                          <Ionicons name="remove" size={20} color="#EF4444" />
                        </TouchableOpacity>
                        <TextInput
                          style={styles.quantityInput}
                          value={product.quantity_wasted.toString()}
                          onChangeText={(text) => updateProductQuantity(product.product_id, 'quantity_wasted', parseInt(text) || 0)}
                          keyboardType="numeric"
                        />
                        <TouchableOpacity
                          style={styles.quantityButton}
                          onPress={() => updateProductQuantity(product.product_id, 'quantity_wasted', product.quantity_wasted + 1)}
                        >
                          <Ionicons name="add" size={20} color="#EF4444" />
                        </TouchableOpacity>
                      </View>
                    </View>

                    <View style={styles.quantityItem}>
                      <Text style={styles.quantityLabel}>Restant</Text>
                      <View style={styles.quantityResult}>
                        <Text style={styles.quantityResultText}>{product.quantity_remaining}</Text>
                      </View>
                    </View>
                  </View>
                </View>
              ))}

              <View style={styles.summaryCard}>
                <Text style={styles.summaryTitle}>Résumé du jour</Text>
                <View style={styles.summaryRow}>
                  <Text style={styles.summaryLabel}>Chiffre d'affaires</Text>
                  <Text style={styles.summaryValue}>{totalRevenue.toFixed(2)} €</Text>
                </View>
              </View>
            </>
          )}
        </ScrollView>

        <View style={styles.footer}>
          <TouchableOpacity style={styles.addButton} onPress={handleAddProducts}>
            <Ionicons name="add-circle-outline" size={24} color="#4A90E2" />
            <Text style={styles.addButtonText}>Gérer les produits</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.saveButton, saving && styles.saveButtonDisabled]}
            onPress={handleSave}
            disabled={saving}
          >
            {saving ? (
              <ActivityIndicator color="#FFF" />
            ) : (
              <>
                <Ionicons name="save-outline" size={24} color="#FFF" />
                <Text style={styles.saveButtonText}>Enregistrer</Text>
              </>
            )}
          </TouchableOpacity>
        </View>

        <Modal
          isVisible={isModalVisible}
          onBackdropPress={() => setIsModalVisible(false)}
          style={styles.modal}
        >
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Sélectionner les produits</Text>
              <TouchableOpacity onPress={() => setIsModalVisible(false)}>
                <Ionicons name="close" size={28} color="#64748B" />
              </TouchableOpacity>
            </View>

            <ScrollView style={styles.modalScroll}>
              {products.map((product) => (
                <TouchableOpacity
                  key={product.id}
                  style={styles.modalProductItem}
                  onPress={() => toggleProductSelection(product.id)}
                >
                  <View style={styles.modalProductInfo}>
                    <Ionicons
                      name={getCategoryIcon(product.category)}
                      size={24}
                      color="#4A90E2"
                    />
                    <View style={styles.modalProductText}>
                      <Text style={styles.modalProductName}>{product.name}</Text>
                      <Text style={styles.modalProductCategory}>
                        {product.category} • {product.price.toFixed(2)} €
                      </Text>
                    </View>
                  </View>
                  <View
                    style={[
                      styles.checkbox,
                      selectedProducts.has(product.id) && styles.checkboxSelected,
                    ]}
                  >
                    {selectedProducts.has(product.id) && (
                      <Ionicons name="checkmark" size={18} color="#FFF" />
                    )}
                  </View>
                </TouchableOpacity>
              ))}
            </ScrollView>

            <TouchableOpacity style={styles.modalConfirmButton} onPress={handleConfirmProducts}>
              <Text style={styles.modalConfirmButtonText}>Confirmer</Text>
            </TouchableOpacity>
          </View>
        </Modal>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#64748B',
  },
  header: {
    backgroundColor: '#FFF',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 8,
  },
  dateContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  dateText: {
    fontSize: 16,
    color: '#64748B',
  },
  content: {
    flex: 1,
    padding: 16,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 80,
  },
  emptyStateText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#64748B',
    marginTop: 16,
  },
  emptyStateSubtext: {
    fontSize: 14,
    color: '#94A3B8',
    marginTop: 8,
    textAlign: 'center',
  },
  productCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  productHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  productInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  productIcon: {
    marginRight: 12,
  },
  productName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
  },
  productCategory: {
    fontSize: 14,
    color: '#64748B',
    marginTop: 2,
  },
  productPrice: {
    fontSize: 14,
    color: '#10B981',
    fontWeight: '600',
    marginTop: 4,
  },
  quantityRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 12,
  },
  quantityItem: {
    flex: 1,
    marginHorizontal: 4,
  },
  quantityLabel: {
    fontSize: 12,
    color: '#64748B',
    marginBottom: 6,
    fontWeight: '600',
  },
  quantityControl: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  quantityButton: {
    padding: 8,
    minWidth: 44,
    minHeight: 44,
    justifyContent: 'center',
    alignItems: 'center',
  },
  quantityInput: {
    flex: 1,
    textAlign: 'center',
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
    minHeight: 44,
  },
  quantityResult: {
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    alignItems: 'center',
    minHeight: 44,
    justifyContent: 'center',
  },
  quantityResultText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
  },
  summaryCard: {
    backgroundColor: '#4A90E2',
    borderRadius: 12,
    padding: 20,
    marginTop: 8,
    marginBottom: 16,
  },
  summaryTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFF',
    marginBottom: 12,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  summaryLabel: {
    fontSize: 16,
    color: '#E0F2FE',
  },
  summaryValue: {
    fontSize: 24,
    fontWeight: '700',
    color: '#FFF',
  },
  footer: {
    backgroundColor: '#FFF',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    flexDirection: 'row',
    gap: 12,
  },
  addButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    padding: 16,
    borderWidth: 2,
    borderColor: '#4A90E2',
    minHeight: 56,
  },
  addButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#4A90E2',
    marginLeft: 8,
  },
  saveButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#4A90E2',
    borderRadius: 12,
    padding: 16,
    minHeight: 56,
  },
  saveButtonDisabled: {
    opacity: 0.6,
  },
  saveButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFF',
    marginLeft: 8,
  },
  modal: {
    justifyContent: 'flex-end',
    margin: 0,
  },
  modalContent: {
    backgroundColor: '#FFF',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1E293B',
  },
  modalScroll: {
    maxHeight: 400,
  },
  modalProductItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  modalProductInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  modalProductText: {
    marginLeft: 12,
    flex: 1,
  },
  modalProductName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
  },
  modalProductCategory: {
    fontSize: 14,
    color: '#64748B',
    marginTop: 2,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: '#CBD5E1',
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxSelected: {
    backgroundColor: '#4A90E2',
    borderColor: '#4A90E2',
  },
  modalConfirmButton: {
    backgroundColor: '#4A90E2',
    margin: 16,
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    minHeight: 56,
    justifyContent: 'center',
  },
  modalConfirmButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFF',
  },
});

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
import Modal from 'react-native-modal';
import axios from 'axios';

const API_URL = process.env.EXPO_PUBLIC_BACKEND_URL;

interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  is_recurring: boolean;
  is_archived: boolean;
}

export default function ProductsScreen() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    category: 'viennoiserie',
    price: '',
    is_recurring: true,
  });

  useEffect(() => {
    loadProducts();
  }, []);

  const loadProducts = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/api/products`);
      setProducts(response.data);
    } catch (error) {
      console.error('Error loading products:', error);
      Alert.alert('Erreur', 'Impossible de charger les produits');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (product?: Product) => {
    if (product) {
      setIsEditMode(true);
      setSelectedProduct(product);
      setFormData({
        name: product.name,
        category: product.category,
        price: product.price.toString(),
        is_recurring: product.is_recurring,
      });
    } else {
      setIsEditMode(false);
      setSelectedProduct(null);
      setFormData({
        name: '',
        category: 'viennoiserie',
        price: '',
        is_recurring: true,
      });
    }
    setIsModalVisible(true);
  };

  const handleCloseModal = () => {
    setIsModalVisible(false);
    setIsEditMode(false);
    setSelectedProduct(null);
    setFormData({
      name: '',
      category: 'viennoiserie',
      price: '',
      is_recurring: true,
    });
  };

  const handleSave = async () => {
    if (!formData.name.trim()) {
      Alert.alert('Erreur', 'Le nom du produit est requis');
      return;
    }

    const price = parseFloat(formData.price);
    if (isNaN(price) || price <= 0) {
      Alert.alert('Erreur', 'Le prix doit être un nombre valide');
      return;
    }

    try {
      const productData = {
        name: formData.name.trim(),
        category: formData.category,
        price: price,
        is_recurring: formData.is_recurring,
      };

      if (isEditMode && selectedProduct) {
        await axios.put(`${API_URL}/api/products/${selectedProduct.id}`, productData);
        Alert.alert('Succès', 'Produit mis à jour');
      } else {
        await axios.post(`${API_URL}/api/products`, productData);
        Alert.alert('Succès', 'Produit ajouté');
      }

      handleCloseModal();
      loadProducts();
    } catch (error: any) {
      console.error('Error saving product:', error);
      Alert.alert('Erreur', error.response?.data?.detail || 'Impossible de sauvegarder le produit');
    }
  };

  const handleDelete = (product: Product) => {
    Alert.alert(
      'Supprimer le produit',
      `Êtes-vous sûr de vouloir supprimer "${product.name}" ?`,
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: 'Supprimer',
          style: 'destructive',
          onPress: async () => {
            try {
              await axios.delete(`${API_URL}/api/products/${product.id}`);
              Alert.alert('Succès', 'Produit supprimé');
              loadProducts();
            } catch (error: any) {
              console.error('Error deleting product:', error);
              Alert.alert('Erreur', 'Impossible de supprimer le produit');
            }
          },
        },
      ]
    );
  };

  const handleArchive = async (product: Product) => {
    try {
      await axios.put(`${API_URL}/api/products/${product.id}`, {
        is_archived: !product.is_archived,
      });
      Alert.alert('Succès', product.is_archived ? 'Produit restauré' : 'Produit archivé');
      loadProducts();
    } catch (error: any) {
      console.error('Error archiving product:', error);
      Alert.alert('Erreur', 'Impossible d\'archiver le produit');
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

  const categories = [
    { label: 'Viennoiserie', value: 'viennoiserie' },
    { label: 'Gâteau', value: 'gâteau' },
    { label: 'Autre', value: 'autre' },
  ];

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
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Catalogue Produits</Text>
        <Text style={styles.headerSubtitle}>{products.length} produit(s)</Text>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {products.length === 0 ? (
          <View style={styles.emptyState}>
            <Ionicons name="basket-outline" size={64} color="#CBD5E1" />
            <Text style={styles.emptyStateText}>Aucun produit</Text>
            <Text style={styles.emptyStateSubtext}>Ajoutez votre premier produit pour commencer</Text>
          </View>
        ) : (
          products.map((product) => (
            <View key={product.id} style={styles.productCard}>
              <View style={styles.productHeader}>
                <View style={styles.productInfo}>
                  <Ionicons
                    name={getCategoryIcon(product.category)}
                    size={32}
                    color="#4A90E2"
                    style={styles.productIcon}
                  />
                  <View style={styles.productDetails}>
                    <Text style={styles.productName}>{product.name}</Text>
                    <Text style={styles.productCategory}>{product.category}</Text>
                    <View style={styles.productMeta}>
                      <Text style={styles.productPrice}>{product.price.toFixed(2)} €</Text>
                      {product.is_recurring && (
                        <View style={styles.recurringBadge}>
                          <Text style={styles.recurringText}>Récurrent</Text>
                        </View>
                      )}
                    </View>
                  </View>
                </View>

                <View style={styles.productActions}>
                  <TouchableOpacity
                    style={styles.actionButton}
                    onPress={() => handleOpenModal(product)}
                  >
                    <Ionicons name="pencil-outline" size={20} color="#4A90E2" />
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.actionButton}
                    onPress={() => handleDelete(product)}
                  >
                    <Ionicons name="trash-outline" size={20} color="#EF4444" />
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          ))
        )}
      </ScrollView>

      <View style={styles.footer}>
        <TouchableOpacity
          style={styles.addButton}
          onPress={() => handleOpenModal()}
        >
          <Ionicons name="add-circle" size={24} color="#FFF" />
          <Text style={styles.addButtonText}>Ajouter un produit</Text>
        </TouchableOpacity>
      </View>

      <Modal
        isVisible={isModalVisible}
        onBackdropPress={handleCloseModal}
        style={styles.modal}
        avoidKeyboard
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={{ flex: 1, justifyContent: 'flex-end' }}
        >
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>
                {isEditMode ? 'Modifier le produit' : 'Nouveau produit'}
              </Text>
              <TouchableOpacity onPress={handleCloseModal}>
                <Ionicons name="close" size={28} color="#64748B" />
              </TouchableOpacity>
            </View>

            <ScrollView style={styles.modalForm}>
              <View style={styles.formGroup}>
                <Text style={styles.formLabel}>Nom du produit</Text>
                <TextInput
                  style={styles.formInput}
                  placeholder="Ex: Croissant"
                  value={formData.name}
                  onChangeText={(text) => setFormData({ ...formData, name: text })}
                />
              </View>

              <View style={styles.formGroup}>
                <Text style={styles.formLabel}>Catégorie</Text>
                <View style={styles.categoryButtons}>
                  {categories.map((cat) => (
                    <TouchableOpacity
                      key={cat.value}
                      style={[
                        styles.categoryButton,
                        formData.category === cat.value && styles.categoryButtonActive,
                      ]}
                      onPress={() => setFormData({ ...formData, category: cat.value })}
                    >
                      <Text
                        style={[
                          styles.categoryButtonText,
                          formData.category === cat.value && styles.categoryButtonTextActive,
                        ]}
                      >
                        {cat.label}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>

              <View style={styles.formGroup}>
                <Text style={styles.formLabel}>Prix (€)</Text>
                <TextInput
                  style={styles.formInput}
                  placeholder="Ex: 1.50"
                  value={formData.price}
                  onChangeText={(text) => setFormData({ ...formData, price: text })}
                  keyboardType="decimal-pad"
                />
              </View>

              <TouchableOpacity
                style={styles.recurringToggle}
                onPress={() =>
                  setFormData({ ...formData, is_recurring: !formData.is_recurring })
                }
              >
                <View style={styles.recurringToggleLeft}>
                  <Ionicons name="repeat-outline" size={24} color="#4A90E2" />
                  <View style={styles.recurringToggleText}>
                    <Text style={styles.recurringToggleTitle}>Produit récurrent</Text>
                    <Text style={styles.recurringToggleSubtitle}>
                      Apparait automatiquement dans les inventaires
                    </Text>
                  </View>
                </View>
                <View
                  style={[
                    styles.toggle,
                    formData.is_recurring && styles.toggleActive,
                  ]}
                >
                  <View
                    style={[
                      styles.toggleCircle,
                      formData.is_recurring && styles.toggleCircleActive,
                    ]}
                  />
                </View>
              </TouchableOpacity>
            </ScrollView>

            <View style={styles.modalFooter}>
              <TouchableOpacity style={styles.cancelButton} onPress={handleCloseModal}>
                <Text style={styles.cancelButtonText}>Annuler</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.saveModalButton} onPress={handleSave}>
                <Text style={styles.saveModalButtonText}>
                  {isEditMode ? 'Modifier' : 'Ajouter'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>
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
    marginBottom: 4,
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#64748B',
  },
  content: {
    flex: 1,
    padding: 16,
  },
  emptyState: {
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
  },
  productInfo: {
    flexDirection: 'row',
    flex: 1,
  },
  productIcon: {
    marginRight: 12,
  },
  productDetails: {
    flex: 1,
  },
  productName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 4,
  },
  productCategory: {
    fontSize: 14,
    color: '#64748B',
    marginBottom: 8,
    textTransform: 'capitalize',
  },
  productMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  productPrice: {
    fontSize: 16,
    fontWeight: '700',
    color: '#10B981',
  },
  recurringBadge: {
    backgroundColor: '#DBEAFE',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  recurringText: {
    fontSize: 12,
    color: '#1E40AF',
    fontWeight: '600',
  },
  productActions: {
    flexDirection: 'row',
    gap: 8,
  },
  actionButton: {
    width: 44,
    height: 44,
    borderRadius: 8,
    backgroundColor: '#F8FAFC',
    alignItems: 'center',
    justifyContent: 'center',
  },
  footer: {
    backgroundColor: '#FFF',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#4A90E2',
    borderRadius: 12,
    padding: 16,
    minHeight: 56,
  },
  addButtonText: {
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
    maxHeight: '90%',
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
  modalForm: {
    padding: 20,
  },
  formGroup: {
    marginBottom: 20,
  },
  formLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 8,
  },
  formInput: {
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: '#1E293B',
    minHeight: 48,
  },
  categoryButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  categoryButton: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    backgroundColor: '#F8FAFC',
    borderWidth: 2,
    borderColor: '#E2E8F0',
    alignItems: 'center',
    minHeight: 48,
    justifyContent: 'center',
  },
  categoryButtonActive: {
    backgroundColor: '#EFF6FF',
    borderColor: '#4A90E2',
  },
  categoryButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
  },
  categoryButtonTextActive: {
    color: '#4A90E2',
  },
  recurringToggle: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  recurringToggleLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  recurringToggleText: {
    marginLeft: 12,
    flex: 1,
  },
  recurringToggleTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
  },
  recurringToggleSubtitle: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  toggle: {
    width: 51,
    height: 31,
    borderRadius: 16,
    backgroundColor: '#CBD5E1',
    padding: 2,
    justifyContent: 'center',
  },
  toggleActive: {
    backgroundColor: '#4A90E2',
  },
  toggleCircle: {
    width: 27,
    height: 27,
    borderRadius: 14,
    backgroundColor: '#FFF',
  },
  toggleCircleActive: {
    transform: [{ translateX: 20 }],
  },
  modalFooter: {
    flexDirection: 'row',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    gap: 12,
  },
  cancelButton: {
    flex: 1,
    padding: 16,
    borderRadius: 12,
    backgroundColor: '#F8FAFC',
    alignItems: 'center',
    minHeight: 56,
    justifyContent: 'center',
  },
  cancelButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#64748B',
  },
  saveModalButton: {
    flex: 1,
    padding: 16,
    borderRadius: 12,
    backgroundColor: '#4A90E2',
    alignItems: 'center',
    minHeight: 56,
    justifyContent: 'center',
  },
  saveModalButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFF',
  },
});

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { format, subDays } from 'date-fns';
import { fr } from 'date-fns/locale';
import axios from 'axios';

const API_URL = process.env.EXPO_PUBLIC_BACKEND_URL;

interface ProductStat {
  product_id: string;
  product_name: string;
  category: string;
  total_produced: number;
  total_sold: number;
  total_wasted: number;
  total_revenue: number;
  avg_sold_per_day: number;
}

interface StatsSummary {
  total_sales: number;
  total_wasted: number;
  total_sold: number;
  total_produced: number;
  products_stats: ProductStat[];
}

interface DailyInventory {
  id: string;
  date: string;
  total_revenue: number;
  products: any[];
}

export default function StatsScreen() {
  const [stats, setStats] = useState<StatsSummary | null>(null);
  const [recentInventories, setRecentInventories] = useState<DailyInventory[]>([]);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<'7' | '30' | 'all'>('7');

  useEffect(() => {
    loadStats();
  }, [period]);

  const loadStats = async () => {
    try {
      setLoading(true);

      const today = format(new Date(), 'yyyy-MM-dd');
      let startDate = '';

      if (period === '7') {
        startDate = format(subDays(new Date(), 7), 'yyyy-MM-dd');
      } else if (period === '30') {
        startDate = format(subDays(new Date(), 30), 'yyyy-MM-dd');
      }

      const params = period !== 'all' ? { start_date: startDate, end_date: today } : {};

      const [statsRes, inventoriesRes] = await Promise.all([
        axios.get(`${API_URL}/api/stats/summary`, { params }),
        axios.get(`${API_URL}/api/inventories`, { params: { limit: 10 } }),
      ]);

      setStats(statsRes.data);
      setRecentInventories(inventoriesRes.data);
    } catch (error) {
      console.error('Error loading stats:', error);
      Alert.alert('Erreur', 'Impossible de charger les statistiques');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async () => {
    try {
      const today = format(new Date(), 'yyyy-MM-dd');
      let startDate = '';

      if (period === '7') {
        startDate = format(subDays(new Date(), 7), 'yyyy-MM-dd');
      } else if (period === '30') {
        startDate = format(subDays(new Date(), 30), 'yyyy-MM-dd');
      }

      const params = period !== 'all' ? { start_date: startDate, end_date: today } : {};
      const response = await axios.get(`${API_URL}/api/export`, { params });

      Alert.alert(
        'Export réussi',
        `Données exportées : ${response.data.inventories.length} inventaires, ${response.data.products.length} produits`,
        [
          {
            text: 'OK',
          },
        ]
      );
    } catch (error) {
      console.error('Error exporting data:', error);
      Alert.alert('Erreur', 'Impossible d\'exporter les données');
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

  const getWastePercentage = (wasted: number, produced: number) => {
    if (produced === 0) return 0;
    return ((wasted / produced) * 100).toFixed(1);
  };

  const getSoldPercentage = (sold: number, produced: number) => {
    if (produced === 0) return 0;
    return ((sold / produced) * 100).toFixed(1);
  };

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
        <Text style={styles.headerTitle}>Statistiques</Text>
        <TouchableOpacity style={styles.exportButton} onPress={handleExport}>
          <Ionicons name="download-outline" size={20} color="#4A90E2" />
          <Text style={styles.exportButtonText}>Export</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.periodSelector}>
        <TouchableOpacity
          style={[styles.periodButton, period === '7' && styles.periodButtonActive]}
          onPress={() => setPeriod('7')}
        >
          <Text style={[styles.periodButtonText, period === '7' && styles.periodButtonTextActive]}>
            7 jours
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.periodButton, period === '30' && styles.periodButtonActive]}
          onPress={() => setPeriod('30')}
        >
          <Text style={[styles.periodButtonText, period === '30' && styles.periodButtonTextActive]}>
            30 jours
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.periodButton, period === 'all' && styles.periodButtonActive]}
          onPress={() => setPeriod('all')}
        >
          <Text style={[styles.periodButtonText, period === 'all' && styles.periodButtonTextActive]}>
            Tout
          </Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {stats && (
          <>
            {/* Summary Cards */}
            <View style={styles.summaryGrid}>
              <View style={[styles.summaryCard, styles.summaryCardRevenue]}>
                <Ionicons name="cash-outline" size={32} color="#10B981" />
                <Text style={styles.summaryCardValue}>{stats.total_sales.toFixed(2)} €</Text>
                <Text style={styles.summaryCardLabel}>Chiffre d'affaires</Text>
              </View>

              <View style={[styles.summaryCard, styles.summaryCardSold]}>
                <Ionicons name="checkmark-circle-outline" size={32} color="#4A90E2" />
                <Text style={styles.summaryCardValue}>{stats.total_sold}</Text>
                <Text style={styles.summaryCardLabel}>Produits vendus</Text>
              </View>

              <View style={[styles.summaryCard, styles.summaryCardWasted]}>
                <Ionicons name="trash-outline" size={32} color="#EF4444" />
                <Text style={styles.summaryCardValue}>{stats.total_wasted}</Text>
                <Text style={styles.summaryCardLabel}>Produits jetés</Text>
              </View>

              <View style={[styles.summaryCard, styles.summaryCardProduced]}>
                <Ionicons name="cube-outline" size={32} color="#F59E0B" />
                <Text style={styles.summaryCardValue}>{stats.total_produced}</Text>
                <Text style={styles.summaryCardLabel}>Produits fabriqués</Text>
              </View>
            </View>

            {/* Products Stats */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Performance par produit</Text>
              {stats.products_stats.length === 0 ? (
                <View style={styles.emptyState}>
                  <Ionicons name="pie-chart-outline" size={48} color="#CBD5E1" />
                  <Text style={styles.emptyStateText}>Aucune donnée disponible</Text>
                </View>
              ) : (
                stats.products_stats.map((product) => (
                  <View key={product.product_id} style={styles.productStatCard}>
                    <View style={styles.productStatHeader}>
                      <View style={styles.productStatInfo}>
                        <Ionicons
                          name={getCategoryIcon(product.category)}
                          size={24}
                          color="#4A90E2"
                          style={styles.productStatIcon}
                        />
                        <View>
                          <Text style={styles.productStatName}>{product.product_name}</Text>
                          <Text style={styles.productStatCategory}>{product.category}</Text>
                        </View>
                      </View>
                      <Text style={styles.productStatRevenue}>
                        {product.total_revenue.toFixed(2)} €
                      </Text>
                    </View>

                    <View style={styles.productStatMetrics}>
                      <View style={styles.productStatMetric}>
                        <Text style={styles.productStatMetricLabel}>Moyenne/jour</Text>
                        <Text style={styles.productStatMetricValue}>
                          {product.avg_sold_per_day} vendus
                        </Text>
                      </View>

                      <View style={styles.productStatMetric}>
                        <Text style={styles.productStatMetricLabel}>Taux de vente</Text>
                        <Text style={[styles.productStatMetricValue, styles.productStatMetricSuccess]}>
                          {getSoldPercentage(product.total_sold, product.total_produced)}%
                        </Text>
                      </View>

                      <View style={styles.productStatMetric}>
                        <Text style={styles.productStatMetricLabel}>Gaspillage</Text>
                        <Text style={[styles.productStatMetricValue, styles.productStatMetricDanger]}>
                          {getWastePercentage(product.total_wasted, product.total_produced)}%
                        </Text>
                      </View>
                    </View>

                    <View style={styles.productStatBar}>
                      <View
                        style={[
                          styles.productStatBarFill,
                          styles.productStatBarSold,
                          {
                            width: `${getSoldPercentage(
                              product.total_sold,
                              product.total_produced
                            )}%`,
                          },
                        ]}
                      />
                      <View
                        style={[
                          styles.productStatBarFill,
                          styles.productStatBarWasted,
                          {
                            width: `${getWastePercentage(
                              product.total_wasted,
                              product.total_produced
                            )}%`,
                          },
                        ]}
                      />
                    </View>
                  </View>
                ))
              )}
            </View>

            {/* Recent Inventories */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Historique récent</Text>
              {recentInventories.length === 0 ? (
                <View style={styles.emptyState}>
                  <Ionicons name="calendar-outline" size={48} color="#CBD5E1" />
                  <Text style={styles.emptyStateText}>Aucun inventaire</Text>
                </View>
              ) : (
                recentInventories.map((inventory) => (
                  <View key={inventory.id} style={styles.historyCard}>
                    <View style={styles.historyHeader}>
                      <View style={styles.historyDate}>
                        <Ionicons name="calendar-outline" size={20} color="#4A90E2" />
                        <Text style={styles.historyDateText}>
                          {format(new Date(inventory.date), 'dd MMM yyyy', { locale: fr })}
                        </Text>
                      </View>
                      <Text style={styles.historyRevenue}>
                        {inventory.total_revenue.toFixed(2)} €
                      </Text>
                    </View>
                    <Text style={styles.historyProducts}>
                      {inventory.products.length} produit(s)
                    </Text>
                  </View>
                ))
              )}
            </View>
          </>
        )}
      </ScrollView>
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
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1E293B',
  },
  exportButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#4A90E2',
  },
  exportButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#4A90E2',
    marginLeft: 6,
  },
  periodSelector: {
    flexDirection: 'row',
    padding: 16,
    gap: 8,
    backgroundColor: '#FFF',
  },
  periodButton: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 8,
    backgroundColor: '#F8FAFC',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  periodButtonActive: {
    backgroundColor: '#4A90E2',
    borderColor: '#4A90E2',
  },
  periodButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
  },
  periodButtonTextActive: {
    color: '#FFF',
  },
  content: {
    flex: 1,
    padding: 16,
  },
  summaryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginBottom: 24,
  },
  summaryCard: {
    width: '48%',
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  summaryCardRevenue: {
    borderTopWidth: 3,
    borderTopColor: '#10B981',
  },
  summaryCardSold: {
    borderTopWidth: 3,
    borderTopColor: '#4A90E2',
  },
  summaryCardWasted: {
    borderTopWidth: 3,
    borderTopColor: '#EF4444',
  },
  summaryCardProduced: {
    borderTopWidth: 3,
    borderTopColor: '#F59E0B',
  },
  summaryCardValue: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1E293B',
    marginTop: 8,
  },
  summaryCardLabel: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 4,
    textAlign: 'center',
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 12,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 40,
    backgroundColor: '#FFF',
    borderRadius: 12,
  },
  emptyStateText: {
    fontSize: 14,
    color: '#94A3B8',
    marginTop: 8,
  },
  productStatCard: {
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
  productStatHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  productStatInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  productStatIcon: {
    marginRight: 12,
  },
  productStatName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
  },
  productStatCategory: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  productStatRevenue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#10B981',
  },
  productStatMetrics: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  productStatMetric: {
    flex: 1,
    alignItems: 'center',
  },
  productStatMetricLabel: {
    fontSize: 12,
    color: '#64748B',
    marginBottom: 4,
  },
  productStatMetricValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
  },
  productStatMetricSuccess: {
    color: '#10B981',
  },
  productStatMetricDanger: {
    color: '#EF4444',
  },
  productStatBar: {
    height: 8,
    backgroundColor: '#F1F5F9',
    borderRadius: 4,
    flexDirection: 'row',
    overflow: 'hidden',
  },
  productStatBarFill: {
    height: '100%',
  },
  productStatBarSold: {
    backgroundColor: '#10B981',
  },
  productStatBarWasted: {
    backgroundColor: '#EF4444',
  },
  historyCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  historyHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  historyDate: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  historyDateText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
  },
  historyRevenue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#10B981',
  },
  historyProducts: {
    fontSize: 14,
    color: '#64748B',
  },
});

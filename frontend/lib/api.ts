import axios from 'axios'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8001'

export const api = axios.create({
  baseURL: `${API_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Types
export interface Product {
  id: string
  name: string
  category: string
  price: number
  is_recurring: boolean
  is_archived: boolean
}

export interface InventoryProduct {
  product_id: string
  product_name: string
  category: string
  quantity_produced: number
  quantity_sold: number
  quantity_wasted: number
  quantity_remaining: number
  price: number
}

export interface DailyInventory {
  id?: string
  date: string
  products: InventoryProduct[]
  total_revenue: number
  created_at?: string
  updated_at?: string
}

export interface StatsSummary {
  total_sales: number
  total_wasted: number
  total_sold: number
  total_produced: number
  products_stats: ProductStat[]
}

export interface ProductStat {
  product_id: string
  product_name: string
  category: string
  total_produced: number
  total_sold: number
  total_wasted: number
  total_revenue: number
  avg_sold_per_day: number
}

// API Functions
export const productApi = {
  getAll: () => api.get<Product[]>('/products'),
  getOne: (id: string) => api.get<Product>(`/products/${id}`),
  create: (data: Omit<Product, 'id' | 'is_archived'>) => api.post<Product>('/products', data),
  update: (id: string, data: Partial<Product>) => api.put<Product>(`/products/${id}`, data),
  delete: (id: string) => api.delete(`/products/${id}`),
}

export const inventoryApi = {
  getAll: (limit = 30) => api.get<DailyInventory[]>('/inventories', { params: { limit } }),
  getByDate: (date: string) => api.get<DailyInventory>(`/inventories/${date}`),
  create: (data: { date: string; products: InventoryProduct[] }) => api.post<DailyInventory>('/inventories', data),
  update: (date: string, data: { products: InventoryProduct[] }) => api.put<DailyInventory>(`/inventories/${date}`, data),
  delete: (date: string) => api.delete(`/inventories/${date}`),
}

export const statsApi = {
  getSummary: (startDate?: string, endDate?: string) => 
    api.get<StatsSummary>('/stats/summary', { params: { start_date: startDate, end_date: endDate } }),
  getProductStats: (productId: string, startDate?: string, endDate?: string) =>
    api.get(`/stats/product/${productId}`, { params: { start_date: startDate, end_date: endDate } }),
  export: (startDate?: string, endDate?: string) =>
    api.get('/export', { params: { start_date: startDate, end_date: endDate } }),
}

// Payroll types and APIs
export interface Employee {
  id: string
  full_name: string
  role?: string
  base_salary: number
  is_active: boolean
  created_at?: string
}

export interface PayrollEntry {
  id?: string
  employee_id: string
  period: string // YYYY-MM
  advances: number
  paid: number
  notes?: string
  created_at?: string
}

export const employeesApi = {
  getAll: (includeInactive = false) => api.get<Employee[]>('/employees', { params: { include_inactive: includeInactive } }),
  create: (data: Omit<Employee, 'id' | 'is_active' | 'created_at'>) => api.post<Employee>('/employees', data),
  update: (id: string, data: Partial<Employee>) => api.put<Employee>(`/employees/${id}`, data),
  delete: (id: string) => api.delete(`/employees/${id}`),
}

export const payrollApi = {
  getAll: (params?: { employee_id?: string; period?: string }) => api.get<PayrollEntry[]>('/payrolls', { params }),
  create: (data: Omit<PayrollEntry, 'id' | 'created_at'>) => api.post<PayrollEntry>('/payrolls', data),
  update: (id: string, data: Partial<PayrollEntry>) => api.put<PayrollEntry>(`/payrolls/${id}`, data),
  delete: (id: string) => api.delete(`/payrolls/${id}`),
}

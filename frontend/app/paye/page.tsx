'use client'

import { useEffect, useMemo, useState } from 'react'
import { Plus, Save, Trash2, Users, CalendarDays, Pencil } from 'lucide-react'
import { employeesApi, payrollApi, type Employee, type PayrollEntry } from '@/lib/api'
import { format } from 'date-fns'
import { CURRENCY_SYMBOL, formatCurrency } from '@/lib/currency'

export default function PayePage() {
  const [employees, setEmployees] = useState<Employee[]>([])
  const [payrolls, setPayrolls] = useState<PayrollEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [showEmployeeModal, setShowEmployeeModal] = useState(false)
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null)
  const [employeeForm, setEmployeeForm] = useState({ full_name: '', role: '', base_salary: '' })
  const [period, setPeriod] = useState(format(new Date(), 'yyyy-MM'))
  const [selectedEmployeeId, setSelectedEmployeeId] = useState<string>('')
  const [savingEmployee, setSavingEmployee] = useState(false)
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null)
  const [advanceInputs, setAdvanceInputs] = useState<Record<string, string>>({})

  useEffect(() => {
    loadData()
  }, [])

  useEffect(() => {
    loadPayrolls()
  }, [period, selectedEmployeeId])

  const loadData = async () => {
    try {
      setLoading(true)
      const [emps] = await Promise.all([employeesApi.getAll()])
      setEmployees(emps.data)
    } finally {
      setLoading(false)
    }
  }

  const loadPayrolls = async () => {
    const res = await payrollApi.getAll({
      employee_id: selectedEmployeeId || undefined,
      period: period || undefined,
    })
    setPayrolls(res.data)
  }

  const handleOpenEmployeeModal = (employee?: Employee) => {
    if (employee) {
      setEditingEmployee(employee)
      setEmployeeForm({
        full_name: employee.full_name,
        role: employee.role || '',
        base_salary: (employee.base_salary || 0).toString(),
      })
    } else {
      setEditingEmployee(null)
      setEmployeeForm({ full_name: '', role: '', base_salary: '' })
    }
    setShowEmployeeModal(true)
  }

  const handleSaveEmployee = async () => {
    if (!employeeForm.full_name.trim()) {
      setToast({ message: 'Le nom complet est requis', type: 'error' })
      return
    }
    try {
      setSavingEmployee(true)
      const payload = {
        full_name: employeeForm.full_name.trim(),
        role: employeeForm.role || undefined,
        base_salary: parseFloat(employeeForm.base_salary || '0') || 0,
      }
      if (editingEmployee) {
        await employeesApi.update(editingEmployee.id, payload as any)
        setToast({ message: 'Salarié modifié', type: 'success' })
      } else {
        await employeesApi.create(payload as any)
        setToast({ message: 'Salarié créé', type: 'success' })
      }
      setShowEmployeeModal(false)
      setEmployeeForm({ full_name: '', role: '', base_salary: '' })
      setEditingEmployee(null)
      loadData()
    } catch (e: any) {
      console.error('Error saving employee:', e)
      setToast({ message: e?.response?.data?.detail || 'Impossible de sauvegarder le salarié', type: 'error' })
    } finally {
      setSavingEmployee(false)
    }
  }

  const handleDeleteEmployee = async (employee: Employee) => {
    if (!confirm(`Êtes-vous sûr de vouloir supprimer "${employee.full_name}" ?`)) {
      return
    }
    try {
      await employeesApi.delete(employee.id)
      setToast({ message: 'Salarié supprimé', type: 'success' })
      loadData()
    } catch (e: any) {
      console.error('Error deleting employee:', e)
      setToast({ message: e?.response?.data?.detail || 'Impossible de supprimer le salarié', type: 'error' })
    }
  }

  const handleAddAdvance = async (employee: Employee) => {
    const key = employee.id
    const raw = advanceInputs[key] ?? ''
    const amount = parseFloat(raw || '0') || 0
    if (amount <= 0) {
      setToast({ message: 'Montant d’avance invalide', type: 'error' })
      return
    }

    const existing = payrolls.find(p => p.employee_id === employee.id && p.period === period)
    const currentTotal = existing?.advances || 0
    const newTotal = currentTotal + amount

    if (existing && existing.id) {
      await payrollApi.update(existing.id, { advances: newTotal })
    } else {
      await payrollApi.create({
        employee_id: employee.id,
        period,
        advances: newTotal,
        notes: '',
      })
    }

    setAdvanceInputs((prev) => ({ ...prev, [key]: '' }))
    setToast({ message: 'Avance enregistrée', type: 'success' })
    loadPayrolls()
  }

  const totals = useMemo(() => {
    const filtered = payrolls
    const totalBase = employees
      .filter(e => !selectedEmployeeId || e.id === selectedEmployeeId)
      .reduce((sum, e) => sum + (e.base_salary || 0), 0)
    const totalAdvances = filtered.reduce((s, p) => s + (p.advances || 0), 0)
    const totalRemaining = totalBase - totalAdvances
    return { totalBase, totalAdvances, totalRemaining }
  }, [employees, payrolls, selectedEmployeeId])

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
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 mb-1">Paye</h1>
            <p className="text-slate-600">Gestion des salariés et bulletins</p>
          </div>
          <div className="flex space-x-3">
            <div className="flex items-center space-x-2">
              <CalendarDays size={18} className="text-slate-600" />
              <input
                type="month"
                value={period}
                onChange={(e) => setPeriod(e.target.value)}
                className="input"
              />
            </div>
            <button onClick={() => handleOpenEmployeeModal()} className="btn-primary">
              <Plus size={18} className="inline mr-2" />
              Nouveau salarié
            </button>
          </div>
        </div>

        {/* Filters */}
        <div className="flex items-center space-x-3">
          <Users size={18} className="text-slate-600" />
          <select
            value={selectedEmployeeId}
            onChange={(e) => setSelectedEmployeeId(e.target.value)}
            className="input"
          >
            <option value="">Tous les salariés</option>
            {employees.map((e) => (
              <option key={e.id} value={e.id}>{e.full_name}</option>
            ))}
          </select>
        </div>

        {/* Summary */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="card border-t-4 border-t-primary">
            <p className="text-sm text-slate-600 mb-1">Salaires de base</p>
            <p className="text-2xl font-bold">{formatCurrency(totals.totalBase)}</p>
          </div>
          <div className="card border-t-4 border-t-warning">
            <p className="text-sm text-slate-600 mb-1">Avances</p>
            <p className="text-2xl font-bold">{formatCurrency(totals.totalAdvances)}</p>
          </div>
          <div className="card border-t-4 border-t-danger">
            <p className="text-sm text-slate-600 mb-1">Reste à payer</p>
            <p className="text-2xl font-bold">{formatCurrency(totals.totalRemaining)}</p>
          </div>
        </div>

        {/* Table */}
        <div className="card">
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr className="text-left text-slate-600">
                  <th className="p-3">Salarié</th>
                  <th className="p-3">Poste</th>
                  <th className="p-3">Salaire base ({CURRENCY_SYMBOL})</th>
                  <th className="p-3">Somme avances</th>
                  <th className="p-3">Nouvelle avance</th>
                  <th className="p-3">Reste</th>
                  <th className="p-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {employees
                  .filter(e => !selectedEmployeeId || e.id === selectedEmployeeId)
                  .map((e) => {
                    const entry = payrolls.find(p => p.employee_id === e.id && p.period === period) || {
                      employee_id: e.id,
                      period,
                      advances: 0,
                      notes: '',
                    }
                    const remaining = (e.base_salary || 0) - (entry.advances || 0)
                    return (
                      <tr key={e.id} className="border-t border-slate-100">
                        <td className="p-3 font-medium text-slate-900">{e.full_name}</td>
                        <td className="p-3 text-slate-700">{e.role || '-'}</td>
                        <td className="p-3">{formatCurrency(e.base_salary || 0)}</td>
                        <td className="p-3">
                          {formatCurrency(entry.advances || 0)}
                        </td>
                        <td className="p-3">
                          <input
                            type="number"
                            className="input w-28"
                            value={advanceInputs[e.id] ?? ''}
                            onChange={(ev) => {
                              setAdvanceInputs((prev) => ({ ...prev, [e.id]: ev.target.value }))
                            }}
                          />
                        </td>
                        <td className="p-3 font-semibold">{formatCurrency(remaining)}</td>
                        <td className="p-3">
                          <div className="flex items-center justify-end space-x-2">
                            <button
                              className="px-3 py-1 rounded-lg border border-slate-200 hover:bg-slate-50"
                              onClick={() => handleAddAdvance(e)}
                            >
                              <Save size={16} className="inline mr-1" /> Avance
                            </button>
                            <button
                              className="p-2 text-primary hover:bg-blue-50 rounded-lg transition-colors"
                              onClick={() => handleOpenEmployeeModal(e)}
                              title="Modifier"
                            >
                              <Pencil size={18} />
                            </button>
                            <button
                              className="p-2 text-danger hover:bg-red-50 rounded-lg transition-colors"
                              onClick={() => handleDeleteEmployee(e)}
                              title="Supprimer"
                            >
                              <Trash2 size={18} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    )
                  })}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Employee Modal */}
      {showEmployeeModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl max-w-lg w-full">
            <div className="p-6 border-b border-slate-200">
              <h2 className="text-2xl font-bold text-slate-900">
                {editingEmployee ? 'Modifier le salarié' : 'Nouveau salarié'}
              </h2>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Nom complet</label>
                <input
                  type="text"
                  value={employeeForm.full_name}
                  onChange={(e) => setEmployeeForm({ ...employeeForm, full_name: e.target.value })}
                  className="input"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Poste</label>
                <input
                  type="text"
                  value={employeeForm.role}
                  onChange={(e) => setEmployeeForm({ ...employeeForm, role: e.target.value })}
                  className="input"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Salaire de base ({CURRENCY_SYMBOL})</label>
                <input
                  type="number"
                  step="0.01"
                  value={employeeForm.base_salary}
                  onChange={(e) => setEmployeeForm({ ...employeeForm, base_salary: e.target.value })}
                  className="input"
                />
              </div>
            </div>
            <div className="p-6 border-t border-slate-200 flex space-x-4">
              <button 
                onClick={() => {
                  setShowEmployeeModal(false)
                  setEditingEmployee(null)
                  setEmployeeForm({ full_name: '', role: '', base_salary: '' })
                }} 
                className="btn-secondary flex-1"
              >
                Annuler
              </button>
              <button onClick={handleSaveEmployee} className="btn-primary flex-1" disabled={savingEmployee}>
                {savingEmployee ? 'Enregistrement…' : editingEmployee ? 'Modifier' : 'Créer'}
              </button>
            </div>
          </div>
        </div>
      )}
      {/* Toast */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-50">
          <div
            className={`
              px-4 py-3 rounded-xl shadow-lg border
              ${toast.type === 'success' ? 'bg-green-50 border-green-200 text-green-800' : ''}
              ${toast.type === 'error' ? 'bg-red-50 border-red-200 text-red-800' : ''}
              ${toast.type === 'info' ? 'bg-blue-50 border-blue-200 text-blue-800' : ''}
            `}
            onAnimationEnd={() => setTimeout(() => setToast(null), 2000)}
          >
            {toast.message}
          </div>
        </div>
      )}
    </div>
  )
}



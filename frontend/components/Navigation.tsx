'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { ClipboardList, Package, BarChart3, Wallet, Menu, X } from 'lucide-react'

const navItems = [
  { href: '/inventaire', label: 'Inventaire', icon: ClipboardList },
  { href: '/produits', label: 'Produits', icon: Package },
  { href: '/statistiques', label: 'Statistiques', icon: BarChart3 },
  { href: '/paye', label: 'Paye', icon: Wallet },
]

export default function Navigation() {
  const pathname = usePathname()
  const [isOpen, setIsOpen] = useState(false)

  return (
    <>
      {/* Mobile Header */}
      <div className="md:hidden bg-white border-b border-slate-200 p-4 flex items-center justify-between sticky top-0 z-40">
        <div>
          <h1 className="text-xl font-bold text-primary">🥐 Pâtisserie</h1>
          <p className="text-xs text-slate-600">Gestion d'inventaire</p>
        </div>
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="p-2 rounded-lg hover:bg-slate-100 transition-colors"
          aria-label="Toggle menu"
        >
          {isOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {/* Mobile Overlay */}
      {isOpen && (
        <div
          className="md:hidden fixed inset-0 bg-black bg-opacity-50 z-30"
          onClick={() => setIsOpen(false)}
        />
      )}

      {/* Navigation */}
      <nav className={`
        fixed md:static inset-y-0 left-0 z-40
        w-64 bg-white border-r border-slate-200 flex flex-col
        transform transition-transform duration-300 ease-in-out
        ${isOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}
      `}>
        <div className="hidden md:block p-6 border-b border-slate-200">
          <h1 className="text-2xl font-bold text-primary">🥐 Pâtisserie</h1>
          <p className="text-sm text-slate-600 mt-1">Gestion d'inventaire</p>
        </div>

        <div className="flex-1 p-4 overflow-y-auto">
          <ul className="space-y-2">
            {navItems.map((item) => {
              const Icon = item.icon
              const isActive = pathname === item.href
              
              return (
                <li key={item.href}>
                  <Link
                    href={item.href}
                    onClick={() => setIsOpen(false)}
                    className={`
                      flex items-center space-x-3 px-4 py-3 rounded-lg transition-all
                      ${isActive 
                        ? 'bg-primary text-white shadow-md' 
                        : 'text-slate-700 hover:bg-slate-100'
                      }
                    `}
                  >
                    <Icon size={20} />
                    <span className="font-medium">{item.label}</span>
                  </Link>
                </li>
              )
            })}
          </ul>
        </div>

        <div className="p-4 border-t border-slate-200">
          <p className="text-xs text-slate-500 text-center">
            Version 1.0.0
          </p>
        </div>
      </nav>
    </>
  )
}

'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { ClipboardList, Package, BarChart3, Wallet } from 'lucide-react'

const navItems = [
  { href: '/inventaire', label: 'Inventaire', icon: ClipboardList },
  { href: '/produits', label: 'Produits', icon: Package },
  { href: '/statistiques', label: 'Statistiques', icon: BarChart3 },
  { href: '/paye', label: 'Paye', icon: Wallet },
]

export default function Navigation() {
  const pathname = usePathname()

  return (
    <nav className="w-64 bg-white border-r border-slate-200 flex flex-col">
      <div className="p-6 border-b border-slate-200">
        <h1 className="text-2xl font-bold text-primary">🥐 Pâtisserie</h1>
        <p className="text-sm text-slate-600 mt-1">Gestion d'inventaire</p>
      </div>

      <div className="flex-1 p-4">
        <ul className="space-y-2">
          {navItems.map((item) => {
            const Icon = item.icon
            const isActive = pathname === item.href
            
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
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
  )
}

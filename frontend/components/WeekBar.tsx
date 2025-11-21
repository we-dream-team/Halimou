'use client'

import { addDays, startOfWeek, format, isSameDay } from 'date-fns'
import { fr } from 'date-fns/locale'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useMemo } from 'react'

interface WeekBarProps {
  date: string // 'yyyy-MM-dd'
  onChange: (date: string) => void
  weekStartsOn?: 1 | 0 // 1 = Monday (default), 0 = Sunday
  title?: string
}

export default function WeekBar({ date, onChange, weekStartsOn = 1, title }: WeekBarProps) {
  const referenceDate = useMemo(() => new Date(date), [date])
  const weekStart = startOfWeek(referenceDate, { weekStartsOn, locale: fr })
  const days = Array.from({ length: 7 }).map((_, i) => addDays(weekStart, i))

  const goPrevWeek = () => {
    const prev = addDays(weekStart, -7)
    onChange(format(prev, 'yyyy-MM-dd'))
  }
  const goNextWeek = () => {
    const next = addDays(weekStart, 7)
    onChange(format(next, 'yyyy-MM-dd'))
  }
  const goToday = () => {
    onChange(format(new Date(), 'yyyy-MM-dd'))
  }

  return (
    <div className="bg-white border border-slate-200 rounded-xl mb-6">
      <div className="flex items-center justify-between px-3 py-2 border-b border-slate-200">
        <button
          onClick={goPrevWeek}
          className="p-2 rounded-lg hover:bg-slate-100 text-slate-700"
          aria-label="Semaine précédente"
        >
          <ChevronLeft size={18} />
        </button>
        <div className="flex items-center space-x-3">
          <div className="text-sm font-medium text-slate-700">
            {title ? title + ' • ' : ''}
            {format(weekStart, 'dd MMM', { locale: fr })} – {format(addDays(weekStart, 6), 'dd MMM yyyy', { locale: fr })}
          </div>
          <button
            onClick={goToday}
            className="px-2 py-1 text-xs rounded-lg border border-slate-200 hover:bg-slate-100 text-slate-700"
          >
            Aujourd'hui
          </button>
        </div>
        <button
          onClick={goNextWeek}
          className="p-2 rounded-lg hover:bg-slate-100 text-slate-700"
          aria-label="Semaine suivante"
        >
          <ChevronRight size={18} />
        </button>
      </div>
      <div className="grid grid-cols-7 gap-1 p-2">
        {days.map((d) => {
          const active = isSameDay(d, referenceDate)
          return (
            <button
              key={d.toISOString()}
              onClick={() => onChange(format(d, 'yyyy-MM-dd'))}
              className={`
                flex flex-col items-center py-2 rounded-lg transition-all
                ${active ? 'bg-primary text-white shadow' : 'hover:bg-slate-100 text-slate-700'}
              `}
            >
              <span className="text-xs opacity-80">
                {format(d, 'EEE', { locale: fr })}
              </span>
              <span className="text-lg font-semibold">
                {format(d, 'd', { locale: fr })}
              </span>
            </button>
          )
        })}
      </div>
    </div>
  )
}



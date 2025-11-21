export const CURRENCY_SYMBOL = process.env.NEXT_PUBLIC_CURRENCY || 'DA'

export function formatCurrency(amount: number): string {
  const normalized = Number.isFinite(amount) ? amount : 0
  return `${normalized.toFixed(2)} ${CURRENCY_SYMBOL}`
}



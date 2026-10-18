/**
 * Utilidades das telas da Torre.
 *
 * O warehouse serializa TODO número como string no JSON, mesmo quando o tipo
 * gerado pelo typegen diz `number`. Sem Number(), `toLocaleString` devolve a
 * string intacta e `+` concatena. Tudo passa por num() antes de conta ou formato.
 */
export const num = (v: unknown) => {
  const n = Number(v ?? 0);
  return Number.isFinite(n) ? n : 0;
};

export const reais = (v: unknown, casas = 0) =>
  num(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: casas });

export const milhoes = (v: unknown) =>
  `R$ ${(num(v) / 1e6).toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} mi`;

export const pct = (v: unknown, casas = 0) =>
  `${(num(v) * 100).toLocaleString('pt-BR', { minimumFractionDigits: casas, maximumFractionDigits: casas })}%`;

export const indice = (v: unknown) =>
  num(v).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

export const CAUSAS: Record<string, string> = {
  chuva: 'chuva',
  falta_material: 'falta de material',
  falta_equipamento: 'falta de equipamento',
  mao_de_obra: 'mão de obra',
  retrabalho: 'retrabalho',
  cliente: 'cliente',
  sem_ocorrencia: '—',
};

/** Cor semântica da situação: vermelho é crítico, âmbar é atenção. */
export const corSituacao = (s: string) =>
  s === 'crítico'
    ? 'bg-red-100 text-red-800 dark:bg-red-950 dark:text-red-200'
    : s === 'atenção'
      ? 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-200'
      : 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200';

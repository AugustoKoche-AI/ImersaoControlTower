import { describe, expect, test } from 'vitest';
import { DecisaoSchema } from './routes/decisoes';

// O endpoint que escreve é a porta mais sensível do app: só entra decisão válida.
const valida = {
  projeto_origem: 'P007', projeto_destino: 'P011', recurso_id: 'EQ0017', tipo: 'equipamento',
  decisao: 'aprovada', justificativa: 'Guindaste 90t parado em Paracatu; P011 sem guindaste.',
  horas_recuperadas_mes: '166.0', economia_mes: '157636.68', multa_evitada: '82807.03',
};

describe('DecisaoSchema', () => {
  test('aceita uma decisão válida e converte número que chega como string', () => {
    const p = DecisaoSchema.parse(valida);
    expect(p.multa_evitada).toBeCloseTo(82807.03);
  });
  test('recusa justificativa curta', () => {
    expect(DecisaoSchema.safeParse({ ...valida, justificativa: 'ok' }).success).toBe(false);
  });
  test('recusa código de obra fora do padrão P000', () => {
    expect(DecisaoSchema.safeParse({ ...valida, projeto_destino: "P011'; DROP TABLE x" }).success).toBe(false);
  });
  test('recusa decisão fora de aprovada/recusada', () => {
    expect(DecisaoSchema.safeParse({ ...valida, decisao: 'talvez' }).success).toBe(false);
  });
});

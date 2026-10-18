import {
  useAnalyticsQuery, Button, Card, CardContent, CardHeader, CardTitle, Input, Label, Skeleton,
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@databricks/appkit-ui/react';
import { useState } from 'react';
import { z } from 'zod';
import { CAUSAS, num, pct, reais } from '../../lib/dados';

const RespostaSchema = z.object({ id: z.coerce.number().optional(), usuario: z.string().optional(), erro: z.string().optional() });

// Premissa do simulador: o efeito vale para o PRÓXIMO MÊS (4 semanas).
const SEMANAS = 4;

export function SimuladorPage() {
  const recursos = useAnalyticsQuery('recursos_ociosos', {});
  const obras = useAnalyticsQuery('obras_risco', {});
  const [recursoId, setRecursoId] = useState<string>('');
  const [destinoId, setDestinoId] = useState<string>('');
  const [mobilizacao, setMobilizacao] = useState<string>('25000');
  const [justificativa, setJustificativa] = useState('');
  const [enviando, setEnviando] = useState(false);
  const [resultado, setResultado] = useState<{ ok: boolean; texto: string } | null>(null);

  const recurso = recursos.data?.find((r) => r.recurso_id === recursoId);
  const destinos = (obras.data ?? []).filter((o) => o.situacao !== 'ok' && o.projeto_id !== recurso?.projeto_origem);
  const destino = obras.data?.find((o) => o.projeto_id === destinoId);

  // As contas, à vista de quem decide:
  const horasMes = recurso ? num(recurso.horas_paradas_semana) * SEMANAS : 0;
  const ociosidadeMes = recurso ? num(recurso.custo_ocioso_semana) * SEMANAS : 0;
  const diasCausa = destino
    ? recurso?.tipo_recurso === 'equipe' ? num(destino.dias_falta_mao_de_obra) : num(destino.dias_falta_equipamento)
    : 0;
  const diasEvitados = (diasCausa / 90) * 30;              // impacto dos últimos 90 dias, trazido para 1 mês
  const temContrato = destino?.multa_dia_pct != null;
  const multaEvitada = temContrato && destino
    ? diasEvitados * (num(destino.multa_dia_pct) / 100) * num(destino.valor_contrato) : 0;
  const custoMobilizacao = num(mobilizacao);
  const saldo = ociosidadeMes + multaEvitada - custoMobilizacao;

  async function decidir(decisao: 'aprovada' | 'recusada') {
    if (!recurso || !destino) return;
    setEnviando(true);
    setResultado(null);
    try {
      const r = await fetch('/api/decisoes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          projeto_origem: recurso.projeto_origem, projeto_destino: destino.projeto_id,
          recurso_id: recurso.recurso_id, tipo: recurso.tipo_recurso, decisao, justificativa,
          horas_recuperadas_mes: horasMes.toFixed(1), economia_mes: ociosidadeMes.toFixed(2),
          multa_evitada: multaEvitada.toFixed(2),
        }),
      });
      const corpo = RespostaSchema.parse(await r.json());
      if (!r.ok) throw new Error(corpo.erro ?? r.statusText);
      setResultado({ ok: true, texto: `Decisão nº ${corpo.id} ${decisao} e registrada por ${corpo.usuario}.` });
      setJustificativa('');
    } catch (e) {
      setResultado({ ok: false, texto: e instanceof Error ? e.message : 'Erro ao gravar' });
    } finally {
      setEnviando(false);
    }
  }

  if (recursos.loading || obras.loading) return <Skeleton className="h-96 max-w-5xl mx-auto" />;
  if (recursos.error || obras.error)
    return <div className="text-destructive">Erro: {String(recursos.error ?? obras.error)}</div>;

  return (
    <div className="space-y-6 w-full max-w-5xl mx-auto">
      <div>
        <h2 className="text-2xl font-bold text-foreground">Simulador de realocação</h2>
        <p className="text-sm text-muted-foreground mt-1">
          Escolha um recurso parado e uma obra em risco. A Torre mostra o que muda no próximo mês e você aprova ou recusa.
        </p>
      </div>

      <Card>
        <CardHeader><CardTitle>1 · O quê e para onde</CardTitle></CardHeader>
        <CardContent className="grid md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="recurso">Recurso ocioso (últimas 12 semanas)</Label>
            <Select value={recursoId} onValueChange={(v) => { setRecursoId(v); setDestinoId(''); setResultado(null); }}>
              <SelectTrigger id="recurso"><SelectValue placeholder="Escolha um equipamento ou equipe" /></SelectTrigger>
              <SelectContent>
                {(recursos.data ?? []).map((r) => (
                  <SelectItem key={r.recurso_id} value={r.recurso_id}>
                    {r.recurso_id} · {r.descricao} · {r.projeto_origem} ({r.uf}) · uso {pct(r.utilizacao_media)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="destino">Obra destino (em atenção ou crítica)</Label>
            <Select value={destinoId} onValueChange={(v) => { setDestinoId(v); setResultado(null); }} disabled={!recurso}>
              <SelectTrigger id="destino"><SelectValue placeholder="Escolha a obra" /></SelectTrigger>
              <SelectContent>
                {destinos.map((o) => (
                  <SelectItem key={o.projeto_id} value={o.projeto_id}>
                    {o.obra} · {o.situacao} · causa: {CAUSAS[o.causa_principal] ?? o.causa_principal}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {recurso && destino && (
        <Card>
          <CardHeader><CardTitle>2 · O que muda no próximo mês</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div><div className="text-xs text-muted-foreground">Horas paradas que viram produção</div>
                <div className="text-2xl font-bold">{horasMes.toLocaleString('pt-BR', { maximumFractionDigits: 0 })} h</div></div>
              <div><div className="text-xs text-muted-foreground">Ociosidade que deixa de ser paga</div>
                <div className="text-2xl font-bold">{reais(ociosidadeMes)}</div></div>
              <div><div className="text-xs text-muted-foreground">Dias de atraso evitados no destino</div>
                <div className="text-2xl font-bold">{diasEvitados.toLocaleString('pt-BR', { maximumFractionDigits: 1 })} d</div></div>
              <div><div className="text-xs text-muted-foreground">Multa contratual evitada</div>
                <div className="text-2xl font-bold">{temContrato ? reais(multaEvitada) : '—'}</div></div>
            </div>
            <div className="flex flex-wrap items-end gap-4">
              <div className="space-y-1">
                <Label htmlFor="mob">Custo de mobilização (premissa, R$)</Label>
                <Input id="mob" className="w-40" inputMode="numeric" value={mobilizacao} onChange={(e) => setMobilizacao(e.target.value)} />
              </div>
              <div className={`text-lg font-semibold ${saldo >= 0 ? 'text-emerald-700 dark:text-emerald-300' : 'text-red-700 dark:text-red-300'}`}>
                Saldo do mês: {reais(saldo)}
              </div>
            </div>
            <details className="text-xs text-muted-foreground">
              <summary className="cursor-pointer">Como a conta é feita</summary>
              <ul className="list-disc pl-5 mt-2 space-y-1">
                <li>Horas = horas paradas por semana do recurso (média de 12 semanas) × {SEMANAS} semanas.</li>
                <li>Ociosidade = custo ocioso por semana × {SEMANAS}: o que a Atlas paga hoje sem produzir.</li>
                <li>Dias evitados = dias de impacto por {recurso.tipo_recurso === 'equipe' ? 'mão de obra' : 'falta de equipamento'} no RDO do destino nos últimos 90 dias ÷ 90 × 30.</li>
                <li>Multa evitada = dias evitados × multa diária do contrato × valor do contrato (só obras com contrato digitalizado).</li>
                <li>Atraso projetado do destino hoje: {num(destino.atraso_projetado_dias)} dias (duração ÷ SPI − duração).</li>
              </ul>
            </details>
          </CardContent>
        </Card>
      )}

      {recurso && destino && (
        <Card>
          <CardHeader><CardTitle>3 · Decisão</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <Label htmlFor="just">Justificativa (fica registrada com o seu usuário)</Label>
            <textarea id="just" className="w-full min-h-24 rounded-md border bg-background p-2 text-sm"
                      value={justificativa} onChange={(e) => setJustificativa(e.target.value)}
                      placeholder={`Ex.: mobilizar ${recurso.recurso_id} de ${recurso.projeto_origem} para ${destino.projeto_id} na segunda.`} />
            <div className="flex gap-3">
              <Button disabled={enviando || justificativa.trim().length < 10} onClick={() => void decidir('aprovada')}>Aprovar</Button>
              <Button variant="outline" disabled={enviando || justificativa.trim().length < 10} onClick={() => void decidir('recusada')}>Recusar</Button>
            </div>
            {resultado && (
              <div className={resultado.ok ? 'text-emerald-700 dark:text-emerald-300' : 'text-destructive'}>{resultado.texto}</div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

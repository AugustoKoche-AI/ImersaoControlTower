import { createApp, analytics, genie, lakebase, server } from '@databricks/appkit';
import { registrarRotasDecisoes } from './routes/decisoes';
import { registrarRotaScore } from './routes/score';

// Leitura: config/queries/*.sql no SQL warehouse (gold da Atlas).
// Escrita: Lakebase (Postgres), tabela torre.decisoes.
// Conversa: Genie "Torre de Controle · Diretoria + Contratos".
createApp({
  plugins: [analytics(), genie(), lakebase(), server()],
  // Sem cache: quem acabou de aprovar uma realocação quer ver o número de agora.
  cache: { enabled: false },
  async onPluginsReady(appkit) {
    await registrarRotasDecisoes(appkit);
    registrarRotaScore(appkit);
  },
}).catch(console.error);

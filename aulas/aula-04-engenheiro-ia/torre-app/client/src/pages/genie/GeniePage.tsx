import { GenieChat } from '@databricks/appkit-ui/react';

export function GeniePage() {
  return (
    <div className="space-y-6 w-full max-w-4xl mx-auto">
      <div>
        <h2 className="text-2xl font-bold text-foreground">Perguntar</h2>
        <p className="text-sm text-muted-foreground mt-1">
          Genie &ldquo;Torre de Controle · Diretoria + Contratos&rdquo;: obras, causa do atraso no RDO e o que o contrato diz.
          Experimente: <i>&ldquo;Por que a obra P011 atrasou e o que o contrato diz sobre isso?&rdquo;</i>
        </p>
      </div>
      <div className="h-[min(640px,72vh)] border rounded-lg overflow-hidden">
        <GenieChat alias="default" />
      </div>
    </div>
  );
}

-- Os números do topo da Torre (fotografia de 16/10/2026).
SELECT COUNT(*)                                                    AS projetos_em_andamento,
       COUNT_IF(situacao IN ('crítico', 'atenção'))                AS projetos_em_risco,
       COUNT_IF(situacao = 'crítico')                              AS projetos_criticos,
       COUNT_IF(melancia)                                          AS projetos_melancia,
       SUM(estouro_previsto)                                       AS estouro_previsto,
       SUM(valor_contrato)                                         AS carteira,
       (SELECT COUNT_IF(ruptura_prevista) FROM lakehouse_vertice.gold.cobertura_capacidade) AS rupturas_capacidade,
       (SELECT SUM(multa_cobravel) FROM lakehouse_vertice.gold.contratos_multa_fornecedor
        WHERE na_vigencia_atual)                                   AS multa_a_cobrar
FROM lakehouse_vertice.gold.projeto_situacao_atual
WHERE status = 'em_andamento'

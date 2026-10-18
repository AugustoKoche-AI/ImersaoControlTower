-- Os quatro números do topo da Torre (fotografia de 16/10/2026).
SELECT COUNT(*)                                                    AS obras_em_andamento,
       COUNT_IF(situacao IN ('crítico', 'atenção'))                AS obras_em_risco,
       COUNT_IF(situacao = 'crítico')                              AS obras_criticas,
       SUM(estouro_previsto)                                       AS estouro_previsto,
       SUM(valor_contrato)                                         AS carteira,
       SUM(rupturas_previstas)                                     AS rupturas_previstas
FROM lakehouse_atlas.gold.obra_situacao_atual
WHERE status = 'em_andamento'

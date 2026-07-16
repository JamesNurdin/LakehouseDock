SELECT *
FROM (
    SELECT
        s.s_state,
        sm.sm_type,
        COUNT(*) AS combo_cnt,
        COUNT(DISTINCT s.s_store_sk) AS store_cnt,
        AVG(s.s_floor_space) AS avg_floor_space,
        AVG(LENGTH(sm.sm_contract)) AS avg_contract_len,
        SUM(CASE WHEN sm.sm_carrier = 'UPS' THEN 1 ELSE 0 END) AS ups_cnt,
        MAX(s.s_tax_percentage) AS max_tax_pct,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY COUNT(*) DESC) AS state_rank
    FROM ship_mode sm
    CROSS JOIN store s
    WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT', 'TWO DAY')
      AND s.s_tax_percentage BETWEEN 5.0 AND 10.0
    GROUP BY s.s_state, sm.sm_type
    HAVING COUNT(*) > 100
) AS ranked
WHERE ranked.state_rank <= 5
ORDER BY ranked.sm_type, ranked.combo_cnt DESC

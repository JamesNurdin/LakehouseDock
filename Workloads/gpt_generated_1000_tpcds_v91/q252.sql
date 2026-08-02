WITH distinct_states AS (
    SELECT DISTINCT s_state
    FROM store
    WHERE s_state IN ('CA', 'TX', 'NY')
),
store_return_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_tax_percentage,
        hd.hd_buy_potential,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT hd.hd_demo_sk) AS distinct_households,
        COUNT(DISTINCT r.r_reason_id) AS distinct_reasons,
        CASE 
            WHEN SUM(sr.sr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(sr.sr_net_loss) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE hd.hd_vehicle_count >= 2
      AND hd.hd_buy_potential = '5001-10000'
      AND s.s_state IN ('CA', 'TX', 'NY')
      AND s.s_gmt_offset BETWEEN -8.0 AND -5.0
      AND sr.sr_return_amt > 10.0
      AND sr.sr_return_quantity <= 5
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, s.s_tax_percentage, hd.hd_buy_potential
)
SELECT
    agg.s_store_name,
    agg.s_state,
    agg.hd_buy_potential,
    agg.total_net_loss,
    agg.avg_return_amt,
    agg.distinct_households,
    agg.distinct_reasons,
    agg.loss_category
FROM store_return_agg agg
JOIN distinct_states ds ON agg.s_state = ds.s_state
WHERE agg.s_tax_percentage > (SELECT AVG(s_tax_percentage) FROM store)
  AND agg.avg_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns)
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = agg.s_store_sk
          AND r2.r_reason_desc = 'Damaged product'
    )
ORDER BY agg.total_net_loss DESC

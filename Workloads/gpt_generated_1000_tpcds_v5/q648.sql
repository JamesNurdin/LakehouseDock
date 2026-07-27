WITH store_returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc,
        t.t_meal_time,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_number_employees > 50
      AND t.t_meal_time IN ('breakfast', 'lunch')
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, r.r_reason_desc, t.t_meal_time
)
SELECT
    agg.s_store_name,
    agg.r_reason_desc,
    agg.t_meal_time,
    agg.total_net_loss,
    CASE WHEN agg.total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    'CA_Stores' AS period,
    (SELECT SUM(sr2.sr_refunded_cash)
       FROM store_returns sr2
       WHERE sr2.sr_store_sk = agg.s_store_sk) AS total_refunded_cash
FROM store_returns_agg agg
WHERE agg.s_state = 'CA'
  AND agg.total_net_loss > 0

UNION ALL

SELECT
    agg.s_store_name,
    agg.r_reason_desc,
    agg.t_meal_time,
    agg.total_net_loss,
    CASE WHEN agg.total_net_loss > 500 THEN 'Medium' ELSE 'Low' END AS loss_category,
    'Non_CA_Stores' AS period,
    (SELECT SUM(sr2.sr_refunded_cash)
       FROM store_returns sr2
       WHERE sr2.sr_store_sk = agg.s_store_sk) AS total_refunded_cash
FROM store_returns_agg agg
WHERE agg.s_state <> 'CA'
  AND agg.total_net_loss > 0

ORDER BY total_net_loss DESC
LIMIT 100

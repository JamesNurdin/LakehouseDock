WITH store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_market_id,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_qty,
        AVG(sr.sr_fee) AS avg_fee,
        SUM(CASE WHEN sr.sr_fee > 50 THEN sr.sr_fee ELSE 0 END) AS high_fee_sum
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY', 'FL')
      AND s.s_market_id BETWEEN 1 AND 5
      AND sr.sr_return_quantity > 0
      AND sr.sr_fee BETWEEN 10 AND 100
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, s.s_market_id
)
SELECT
    s_store_sk,
    s_store_name,
    s_state,
    s_market_id,
    total_net_loss,
    total_qty,
    avg_fee,
    high_fee_sum,
    CASE WHEN high_fee_sum > 500 THEN 'Very High'
         WHEN high_fee_sum > 200 THEN 'High'
         ELSE 'Moderate' END AS fee_category,
    RANK() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS state_rank,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS overall_rank
FROM store_agg
ORDER BY total_net_loss DESC, s_state
LIMIT 100

WITH store_return_stats AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        t.t_hour,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_store_credit) AS avg_store_credit,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2452000 AND 2452500
      AND sr.sr_store_credit > 20
      AND sr.sr_return_ship_cost < 1000
      AND c.c_birth_month IN (3, 6, 8)
      AND cd.cd_dep_count >= 1
      AND cd.cd_purchase_estimate >= 1000
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, t.t_hour
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    t_hour,
    total_return_amt,
    total_net_loss,
    avg_store_credit,
    return_cnt,
    RANK() OVER (PARTITION BY s_state ORDER BY total_return_amt DESC) AS store_return_rank_state
FROM store_return_stats
ORDER BY s_state, store_return_rank_state
LIMIT 100

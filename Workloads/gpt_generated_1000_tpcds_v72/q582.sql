WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_profit) AS total_cs_profit,
        SUM(ss.ss_net_profit) AS total_ss_profit,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'FEDEX'
      AND sm.sm_code IN ('AIR', 'SEA')
      AND s.s_state = 'CA'
      AND cs.cs_coupon_amt > 500
      AND ss.ss_quantity BETWEEN 10 AND 100
      AND (wr.wr_return_quantity IS NULL OR wr.wr_return_quantity > 0)
    GROUP BY s.s_store_sk, s.s_state, sm.sm_ship_mode_id
)
SELECT
    s_store_sk,
    s_state,
    sm_ship_mode_id,
    total_cs_profit,
    total_ss_profit,
    txn_cnt,
    RANK() OVER (PARTITION BY s_state ORDER BY total_cs_profit DESC) AS profit_rank,
    CASE
        WHEN total_cs_profit > (SELECT AVG(total_cs_profit) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM sales_agg
ORDER BY profit_rank, total_cs_profit DESC
LIMIT 100

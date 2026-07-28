WITH agg1 AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_closed_date_sk = 2451109
      AND ss.ss_ext_discount_amt > 1000
    GROUP BY s.s_store_id, s.s_city, s.s_state
    HAVING SUM(ss.ss_net_profit) > 5000
),
agg2 AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_closed_date_sk = 2450893
      AND ss.ss_ext_discount_amt BETWEEN 500 AND 1500
    GROUP BY s.s_store_id, s.s_city, s.s_state
    HAVING SUM(ss.ss_net_profit) > 3000
),
combined AS (
    SELECT * FROM agg1
    UNION ALL
    SELECT * FROM agg2
)
SELECT
    c.s_store_id,
    c.s_city,
    c.s_state,
    c.total_profit,
    c.avg_discount,
    c.sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY c.s_state ORDER BY c.total_profit DESC) AS state_rank
FROM combined c
ORDER BY c.total_profit DESC
LIMIT 100

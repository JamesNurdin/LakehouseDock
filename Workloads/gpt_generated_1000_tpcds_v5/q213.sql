WITH sales AS (
    SELECT s.s_store_id AS store_id,
           t.t_sub_shift AS sub_shift,
           SUM(ss.ss_ext_sales_price) AS amount,
           SUM(ss.ss_net_profit) AS profit,
           'sale' AS src
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_sub_shift IN ('morning', 'afternoon')
    GROUP BY s.s_store_id, t.t_sub_shift
),
returns AS (
    SELECT s.s_store_id AS store_id,
           t.t_sub_shift AS sub_shift,
           SUM(r.sr_return_amt) AS amount,
           -SUM(r.sr_net_loss) AS profit,
           'return' AS src
    FROM store_returns r
    JOIN store s ON r.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON r.sr_return_time_sk = t.t_time_sk
    WHERE t.t_sub_shift IN ('morning', 'afternoon')
    GROUP BY s.s_store_id, t.t_sub_shift
)
SELECT combined.store_id,
       combined.sub_shift,
       combined.src,
       combined.amount,
       combined.profit,
       CASE WHEN combined.profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM (
    SELECT store_id, sub_shift, src, amount, profit
    FROM sales
    UNION ALL
    SELECT store_id, sub_shift, src, amount, profit
    FROM returns
) AS combined
ORDER BY combined.store_id,
         combined.sub_shift,
         combined.src
LIMIT 100

WITH base AS (
   SELECT
       ss.ss_store_sk,
       ss.ss_sold_time_sk,
       ss.ss_ext_wholesale_cost,
       ss.ss_net_paid_inc_tax,
       ss.ss_quantity,
       ss.ss_net_profit,
       ss.ss_sales_price
   FROM store_sales ss
   WHERE ss.ss_ext_wholesale_cost > 500
     AND ss.ss_net_paid_inc_tax BETWEEN 100 AND 2000
     AND ss.ss_quantity >= 1
     AND ss.ss_store_sk IN (919, 847, 830, 772, 68)
     AND ss.ss_sales_price > 0
),
target_stores AS (
   SELECT ss_store_sk
   FROM base
   GROUP BY ss_store_sk
   HAVING SUM(ss_net_paid_inc_tax) > 5000
   EXCEPT
   SELECT ss_store_sk
   FROM base
   GROUP BY ss_store_sk
   HAVING SUM(ss_quantity) < 10
),
agg AS (
   SELECT
       t.t_shift,
       b.ss_store_sk,
       SUM(b.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
       SUM(b.ss_ext_wholesale_cost) AS total_wholesale_cost,
       SUM(b.ss_net_profit) AS total_net_profit
   FROM base b
   JOIN time_dim t ON b.ss_sold_time_sk = t.t_time_sk
   JOIN target_stores ts ON b.ss_store_sk = ts.ss_store_sk
   WHERE t.t_shift IN ('first', 'second', 'third')
     AND t.t_sub_shift = 'morning'
     AND EXISTS (
         SELECT 1
         FROM store_sales s2
         WHERE s2.ss_store_sk = b.ss_store_sk
           AND s2.ss_ext_wholesale_cost > 4000
         LIMIT 1
     )
   GROUP BY GROUPING SETS (
       (t.t_shift, b.ss_store_sk),
       (t.t_shift),
       ()
   )
)
SELECT
   t_shift,
   ss_store_sk,
   total_net_paid_inc_tax,
   total_wholesale_cost,
   CASE WHEN total_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
   RANK() OVER (PARTITION BY t_shift ORDER BY total_net_paid_inc_tax DESC) AS rank_within_shift
FROM agg
ORDER BY t_shift, rank_within_shift
LIMIT 100

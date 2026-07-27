WITH base AS (
   SELECT
       s.s_state AS s_state,
       s.s_city AS s_city,
       d.d_month_seq AS d_month_seq,
       ss.ss_net_paid AS ss_net_paid,
       ss.ss_net_profit AS ss_net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND d.d_moy = 7
     AND s.s_state = 'TX'
     AND ws.web_tax_percentage = 0.08
     AND cc.cc_state = 'CA'
     AND t.t_hour BETWEEN 9 AND 17
),
agg AS (
   SELECT
       s_state,
       s_city,
       d_month_seq,
       SUM(ss_net_paid) AS total_net_paid,
       AVG(ss_net_profit) AS avg_net_profit,
       COUNT(*) AS txn_count,
       MIN(ss_net_paid) AS min_net_paid,
       MAX(ss_net_paid) AS max_net_paid
   FROM base
   GROUP BY GROUPING SETS (
       (s_state, s_city, d_month_seq),
       (s_state, s_city),
       (s_state),
       ()
   )
)
SELECT
   s_state,
   s_city,
   d_month_seq,
   total_net_paid,
   avg_net_profit,
   txn_count,
   min_net_paid,
   max_net_paid,
   ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_paid DESC) AS rn_state
FROM agg
ORDER BY s_state, s_city, d_month_seq
LIMIT 100

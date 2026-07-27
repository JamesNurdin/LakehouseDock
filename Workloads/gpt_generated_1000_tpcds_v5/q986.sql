WITH sales_agg AS (
   SELECT
       ss_store_sk,
       ss_sold_date_sk,
       ss_sold_time_sk,
       SUM(ss_net_paid) AS total_net_paid,
       SUM(ss_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt
   FROM store_sales
   WHERE ss_quantity > 1
     AND ss_net_paid > 0
   GROUP BY ss_store_sk, ss_sold_date_sk, ss_sold_time_sk
),
returns_agg AS (
   SELECT
       sr_store_sk,
       sr_returned_date_sk,
       SUM(sr_return_amt) AS total_return_amt,
       SUM(sr_net_loss) AS total_net_loss,
       COUNT(*) AS returns_cnt
   FROM store_returns
   WHERE sr_return_quantity > 0
     AND sr_return_amt > 0
   GROUP BY sr_store_sk, sr_returned_date_sk
)
SELECT
   d_sales.d_year,
   s.s_state,
   ws.web_name,
   t.t_hour,
   SUM(sa.total_net_paid) AS sum_net_paid,
   SUM(sa.total_net_profit) AS sum_net_profit,
   SUM(ra.total_return_amt) AS sum_return_amt,
   COUNT(DISTINCT sa.ss_store_sk) AS distinct_stores
FROM sales_agg sa
JOIN date_dim d_sales ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t ON sa.ss_sold_time_sk = t.t_time_sk
JOIN store s ON sa.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra ON ra.sr_store_sk = s.s_store_sk
                         AND ra.sr_returned_date_sk = d_sales.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_sales.d_year = 2001
  AND s.s_state = 'CA'
  AND t.t_hour IN (13, 17)
  AND ws.web_gmt_offset = -5.00
  AND s.s_tax_percentage > 5.00
GROUP BY d_sales.d_year, s.s_state, ws.web_name, t.t_hour
ORDER BY sum_net_paid DESC
LIMIT 100

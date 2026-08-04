WITH sales_agg AS (
   SELECT
       ss.ss_sold_date_sk,
       ib.ib_income_band_sk,
       SUM(ss.ss_net_profit) AS total_profit,
       CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE d.d_year = 2001
   GROUP BY ss.ss_sold_date_sk, ib.ib_income_band_sk
),
union_customers AS (
   SELECT ss.ss_customer_sk AS customer_id
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   UNION
   SELECT sr.sr_customer_sk AS customer_id
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001 AND sr.sr_return_amt > 100
),
intersect_customers AS (
   SELECT cr.cr_returning_customer_sk AS customer_id
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
final_customers AS (
   SELECT customer_id FROM union_customers
   INTERSECT
   SELECT customer_id FROM intersect_customers
)
SELECT
   fc.customer_id,
   sa.profit_category,
   sa.total_profit
FROM final_customers fc
JOIN store_sales ss ON ss.ss_customer_sk = fc.customer_id
JOIN sales_agg sa ON ss.ss_sold_date_sk = sa.ss_sold_date_sk
WHERE EXISTS (
   SELECT 1
   FROM time_dim t
   WHERE t.t_time_sk = ss.ss_sold_time_sk
     AND t.t_sub_shift = 'morning'
)
ORDER BY sa.total_profit DESC
LIMIT 100

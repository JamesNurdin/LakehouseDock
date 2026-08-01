WITH cc_hours AS (
   SELECT
       c.cc_call_center_sk,
       c.cc_name,
       trim(hour_part) AS hour_part
   FROM call_center c
   CROSS JOIN UNNEST(split(c.cc_hours, ',')) AS t (hour_part)
),
call_center_agg AS (
   SELECT
       d.d_date AS cc_date,
       COUNT(DISTINCT c.cc_call_center_sk) AS center_count,
       MAX(c.cc_gmt_offset) AS max_gmt_offset
   FROM call_center c
   JOIN date_dim d ON c.cc_open_date_sk = d.d_date_sk
   GROUP BY d.d_date
),
store_sales_agg AS (
   SELECT
       d.d_date AS sales_date,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
       CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY d.d_date
),
catalog_returns_agg AS (
   SELECT
       d.d_date AS return_date,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_loss,
       COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
       CASE WHEN SUM(cr.cr_net_loss) > 50000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   GROUP BY d.d_date
),
union_events AS (
   SELECT
       sales_date AS event_date,
       total_sales AS amount,
       total_profit AS profit,
       profit_category AS category,
       'SALE' AS event_type
   FROM store_sales_agg
   UNION
   SELECT
       return_date AS event_date,
       total_return_amount AS amount,
       total_loss AS profit,
       loss_category AS category,
       'RETURN' AS event_type
   FROM catalog_returns_agg
)
SELECT
   u.event_date,
   u.amount,
   u.profit,
   u.category,
   u.event_type,
   ca.center_count,
   ca.max_gmt_offset,
   h.hour_part
FROM union_events u
FULL OUTER JOIN call_center_agg ca ON u.event_date = ca.cc_date
LEFT JOIN (
   SELECT DISTINCT cc_call_center_sk, hour_part
   FROM cc_hours
) h ON ca.center_count IS NOT NULL
WHERE u.event_date >= DATE '2001-01-01'
  AND u.event_date <= DATE '2001-12-31'
ORDER BY u.event_date DESC, u.amount DESC
LIMIT 100

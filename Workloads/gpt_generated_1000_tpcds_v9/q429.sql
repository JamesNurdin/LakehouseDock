WITH base AS (
  SELECT
    ss.ss_ext_sales_price,
    ss.ss_net_paid,
    ss.ss_quantity,
    ca_sales.ca_city,
    w.w_state
  FROM store_sales ss
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
  JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca_returns ON cr.cr_refunded_addr_sk = ca_returns.ca_address_sk
  WHERE w.w_state = 'IN'
    AND w.w_zip = '89275'
    AND p.p_promo_id = 'AAAAAAAADAAAAAAA'
    AND p.p_end_date_sk = 2450592
    AND ca_sales.ca_street_number = '31'
    AND ca_sales.ca_country = 'United States'
    AND ss.ss_net_paid > 1000
    AND cr.cr_return_quantity > 0
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_returning_customer_sk = ss.ss_customer_sk
          AND cr_sub.cr_return_quantity > 0
    )
),
agg AS (
  SELECT
    w_state,
    ca_city,
    SUM(ss_ext_sales_price) AS sum_sales,
    SUM(ss_net_paid) AS sum_net_paid,
    COUNT(*) AS txn_count,
    AVG(ss_quantity) AS avg_quantity,
    MIN(ss_ext_sales_price) AS min_sales,
    MAX(ss_ext_sales_price) AS max_sales
  FROM base
  GROUP BY ROLLUP (w_state, ca_city)
)
SELECT
  w_state,
  ca_city,
  sum_sales,
  sum_net_paid,
  txn_count,
  avg_quantity,
  min_sales,
  max_sales,
  ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY sum_sales DESC) AS rn_state
FROM agg
ORDER BY sum_sales DESC NULLS LAST
LIMIT 100

WITH sales_agg AS (
  SELECT
    ss.ss_customer_sk AS customer_sk,
    ss.ss_store_sk AS store_sk,
    d_sales.d_year AS year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  WHERE d_sales.d_year = 2000
    AND t_sales.t_hour BETWEEN 8 AND 17
    AND s.s_state = 'CA'
  GROUP BY ss.ss_customer_sk, ss.ss_store_sk, d_sales.d_year
),
returns_agg AS (
  SELECT
    cr.cr_refunded_customer_sk AS customer_sk,
    cp.cp_department AS department,
    d_return.d_year AS year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'HAS_RETURN' ELSE 'NO_RETURN' END AS return_flag
  FROM catalog_returns cr
  JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
  JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE d_return.d_year = 2000
    AND sm.sm_type = 'AIR'
    AND cp.cp_type = 'STANDARD'
  GROUP BY cr.cr_refunded_customer_sk, cp.cp_department, d_return.d_year
),
union_customers AS (
  SELECT customer_sk, 'SALES' AS source FROM sales_agg
  UNION ALL
  SELECT customer_sk, 'RETURNS' AS source FROM returns_agg
)
SELECT
  s.s_store_id,
  c.c_customer_id,
  SA.year,
  SA.total_net_profit,
  COALESCE(RA.total_return_amount, 0) AS total_return_amount,
  (SA.total_net_profit - COALESCE(RA.total_return_amount, 0)) AS net_profit_adj,
  SA.sales_cnt,
  RA.return_cnt,
  CASE WHEN SA.total_quantity > 10 THEN 'HIGH_VOLUME' ELSE 'LOW_VOLUME' END AS volume_category,
  wp.wp_url,
  wp.wp_max_ad_count,
  (
    SELECT COUNT(*)
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = c.c_customer_sk
  ) AS customer_page_views,
  RANK() OVER (
    PARTITION BY s.s_store_id
    ORDER BY (SA.total_net_profit - COALESCE(RA.total_return_amount, 0)) DESC
  ) AS profit_rank_by_store
FROM sales_agg SA
LEFT JOIN returns_agg RA
  ON SA.customer_sk = RA.customer_sk
  AND SA.year = RA.year
JOIN store s
  ON SA.store_sk = s.s_store_sk
JOIN customer c
  ON SA.customer_sk = c.c_customer_sk
LEFT JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_web
  ON wp.wp_creation_date_sk = d_web.d_date_sk
WHERE wp.wp_max_ad_count > 0
  AND d_web.d_year = 2000
  AND EXISTS (
    SELECT 1 FROM union_customers uc WHERE uc.customer_sk = c.c_customer_sk
  )
LIMIT 100

WITH
  sales_agg AS (
    SELECT
      s.s_store_sk AS store_sk,
      s.s_store_name AS store_name,
      d_s.d_year AS year,
      SUM(ss.ss_net_paid) AS metric,
      'sales' AS metric_type
    FROM store_sales ss
    JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
    JOIN time_dim t_s ON ss.ss_sold_time_sk = t_s.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d_s.d_year = 2001
      AND p.p_promo_name = 'Clearance'
      AND p.p_channel_tv = 'Y' -- additional realistic filter
    GROUP BY s.s_store_sk, s.s_store_name, d_s.d_year
  ),
  returns_agg AS (
    SELECT
      s.s_store_sk AS store_sk,
      s.s_store_name AS store_name,
      d_r.d_year AS year,
      -SUM(cr.cr_return_amount) AS metric,
      'returns' AS metric_type
    FROM store_sales ss
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = ss.ss_sold_date_sk
                              AND cr.cr_returned_time_sk = ss.ss_sold_time_sk
    JOIN date_dim d_r ON cr.cr_returned_date_sk = d_r.d_date_sk
    JOIN time_dim t_r ON cr.cr_returned_time_sk = t_r.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d_r.d_year = 2001
      AND p.p_promo_name = 'Clearance'
      AND sm.sm_type = 'OVERNIGHT'
      AND w.w_city = 'Chicago'
      AND r.r_reason_desc = 'Customer Dissatisfaction'
    GROUP BY s.s_store_sk, s.s_store_name, d_r.d_year
  ),
  sales_store_ids AS (
    SELECT store_sk FROM sales_agg
  ),
  returns_store_ids AS (
    SELECT store_sk FROM returns_agg
  ),
  sales_not_returns AS (
    SELECT store_sk FROM sales_store_ids
    EXCEPT
    SELECT store_sk FROM returns_store_ids
  ),
  union_data AS (
    SELECT * FROM sales_agg
    UNION
    SELECT * FROM returns_agg
  )
SELECT
  ud.store_name,
  ud.year,
  SUM(ud.metric) AS total_metric,
  COUNT(*) AS rows_count,
  (
    SELECT AVG(ss2.ss_net_paid)
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = ud.store_sk
  ) AS avg_store_sales
FROM union_data ud
WHERE ud.store_sk IN (SELECT store_sk FROM sales_not_returns)
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr3
    JOIN warehouse w3 ON cr3.cr_warehouse_sk = w3.w_warehouse_sk
    WHERE w3.w_city = 'Chicago'
      AND cr3.cr_return_amount > 100
  )
GROUP BY ud.store_sk, ud.store_name, ud.year
HAVING SUM(ud.metric) > 0
ORDER BY total_metric DESC
OFFSET 0 LIMIT 10

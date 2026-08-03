WITH
  -- Sampled web sales facts with many dimensions
  web_data AS (
    SELECT
      d.d_year,
      sm.sm_type,
      p.p_promo_name,
      ws.ws_net_profit AS metric
    FROM (
      SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
    ) ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p              ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site we              ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'EXPRESS'
      AND we.web_country = 'United States'
  ),

  -- Store returns (right‑outer join keeps all stores)
  store_data AS (
    SELECT
      d.d_year,
      CAST(NULL AS varchar) AS sm_type,
      CAST(NULL AS varchar) AS p_promo_name,
      -sr.sr_net_loss AS metric
    FROM store_returns sr
    RIGHT OUTER JOIN store s       ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
      AND s.s_market_id = 1
  ),

  -- Catalog returns filtered by warehouse location
  catalog_data AS (
    SELECT
      d.d_year,
      sm.sm_type,
      CAST(NULL AS varchar) AS p_promo_name,
      -cr.cr_net_loss AS metric
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm             ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_warehouse_sk IN (
            SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'CA'
          )
      AND d.d_year = 2001
      AND sm.sm_type = 'EXPRESS'
  ),

  -- Union of the three sources (deduplicated)
  union_data AS (
    SELECT d_year, sm_type, p_promo_name, metric FROM web_data
    UNION DISTINCT
    SELECT d_year, sm_type, p_promo_name, metric FROM store_data
    UNION DISTINCT
    SELECT d_year, sm_type, p_promo_name, metric FROM catalog_data
  ),

  -- Cube aggregation over the unioned result
  aggregated AS (
    SELECT
      d_year,
      sm_type,
      p_promo_name,
      SUM(metric) AS total_metric,
      COUNT(*)    AS cnt
    FROM union_data
    GROUP BY CUBE (d_year, sm_type, p_promo_name)
  ),

  -- Small set of discount factors for cross‑join
  discounts AS (
    SELECT 0.0 AS discount_factor UNION ALL SELECT 0.05 UNION ALL SELECT 0.10
  )

SELECT
  a.d_year,
  a.sm_type,
  a.p_promo_name,
  a.total_metric,
  a.cnt,
  d.discount_factor,
  a.total_metric * (1 - d.discount_factor) AS adjusted_metric
FROM aggregated a
CROSS JOIN discounts d
WHERE a.total_metric > 1000
ORDER BY a.d_year NULLS LAST, a.total_metric DESC
LIMIT 100

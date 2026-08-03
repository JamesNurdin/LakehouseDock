WITH
  -- Sales per store and promotion during business hours, filtered by regex and pattern
  sales_promo AS (
    SELECT
      s.s_store_id,
      p.p_promo_id,
      p.p_promo_name,
      SUM(ss.ss_net_paid) AS total_paid,
      CONCAT(s.s_store_name, ' - ', p.p_promo_name) AS store_promo_desc
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND regexp_like(p.p_promo_name, '\\d+')
      AND s.s_store_name LIKE 'A%'
    GROUP BY
      s.s_store_id,
      p.p_promo_id,
      p.p_promo_name,
      s.s_store_name
  ),

  -- Expand call_center hours string into an array and unnest it
  cc_hours_expanded AS (
    SELECT
      cc.cc_call_center_sk,
      hour_token,
      regexp_like(hour_token, '^[0-9]+(AM|PM)$') AS is_hour
    FROM call_center cc
    CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t(hour_token)
  ),

  -- Count valid hour tokens per call_center
  cc_agg AS (
    SELECT
      cc_call_center_sk,
      COUNT(*) AS hour_token_count
    FROM cc_hours_expanded
    WHERE is_hour
    GROUP BY cc_call_center_sk
  ),

  -- Stores that have sales
  stores_sales_set AS (
    SELECT DISTINCT s.s_store_id AS s_id
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
  ),

  -- Stores that have returns
  stores_returns_set AS (
    SELECT DISTINCT s.s_store_id AS s_id
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
  ),

  -- Stores with sales but without returns (EXCEPT example)
  stores_without_returns AS (
    SELECT s_id FROM stores_sales_set
    EXCEPT
    SELECT s_id FROM stores_returns_set
  ),

  -- Full outer join catalog sales and returns
  cat_full AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cr.cr_return_amount
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
  ),

  -- Aggregate the full outer join result
  cat_agg AS (
    SELECT
      cs_order_number,
      SUM(cs_net_paid) AS total_sales,
      SUM(cr_return_amount) AS total_returns
    FROM cat_full
    GROUP BY cs_order_number
  )

SELECT
  CAST(s_store_id AS varchar) AS id,
  'store' AS type,
  CAST(total_paid AS decimal(15,2)) AS metric,
  store_promo_desc AS description
FROM sales_promo
WHERE s_store_id IN (SELECT s_id FROM stores_without_returns)

UNION DISTINCT

SELECT
  CAST(cs_order_number AS varchar) AS id,
  'catalog' AS type,
  CAST(total_sales AS decimal(15,2)) AS metric,
  NULL AS description
FROM cat_agg

UNION DISTINCT

SELECT
  CAST(cc_call_center_sk AS varchar) AS id,
  'call_center' AS type,
  CAST(hour_token_count AS decimal(15,2)) AS metric,
  NULL AS description
FROM cc_agg

ORDER BY metric DESC
LIMIT 100

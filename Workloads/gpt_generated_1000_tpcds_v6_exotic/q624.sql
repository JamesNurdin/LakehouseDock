WITH store_sales_agg AS (
  SELECT
    s.s_store_name AS location_name,
    SUM(ss.ss_net_profit) AS total_profit,
    CAST('store' AS varchar) AS source_type,
    ROW_NUMBER() OVER (PARTITION BY CAST('store' AS varchar) ORDER BY SUM(ss.ss_net_profit) DESC) AS rank
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2020
    AND ss.ss_promo_sk IN (
      SELECT p.p_promo_sk
      FROM promotion p
      WHERE p.p_promo_name LIKE '%Clearance%'
    )
    AND EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_store_sk = ss.ss_store_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    )
  GROUP BY s.s_store_name
),
catalog_sales_agg AS (
  SELECT
    w.w_warehouse_name AS location_name,
    SUM(cs.cs_net_profit) AS total_profit,
    CAST('catalog' AS varchar) AS source_type,
    ROW_NUMBER() OVER (PARTITION BY CAST('catalog' AS varchar) ORDER BY SUM(cs.cs_net_profit) DESC) AS rank
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2020
    AND EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_promo_sk = cs.cs_promo_sk
        AND p.p_discount_active = 'Y'
    )
  GROUP BY w.w_warehouse_name
)
SELECT
  location_name,
  total_profit,
  source_type,
  rank
FROM store_sales_agg
UNION ALL
SELECT
  location_name,
  total_profit,
  source_type,
  rank
FROM catalog_sales_agg
ORDER BY total_profit DESC, source_type
LIMIT 100

WITH
  store_sales_agg AS (
    SELECT
      s.s_store_id,
      i.i_item_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_country = 'United States'
    GROUP BY GROUPING SETS (
      (s.s_store_id, i.i_item_id),
      (s.s_store_id),
      (i.i_item_id)
    )
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_web_site_sk,
      i.i_item_id,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE w.web_country = 'United States'
    GROUP BY GROUPING SETS (
      (ws.ws_web_site_sk, i.i_item_id),
      (ws.ws_web_site_sk),
      (i.i_item_id)
    )
  ),
  common_items AS (
    SELECT i_item_id
    FROM store_sales_agg
    WHERE i_item_id IS NOT NULL
    INTERSECT
    SELECT i_item_id
    FROM web_sales_agg
    WHERE i_item_id IS NOT NULL
  ),
  catalog_promo_items AS (
    SELECT
      i.i_item_id,
      'CatalogPromo' AS source,
      CASE
        WHEN SUM(cs.cs_ext_sales_price) > 20000 THEN 'HIGH'
        ELSE 'LOW'
      END AS sales_level
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_item_id IN (SELECT i_item_id FROM item WHERE i_brand = 'Brand#12')
    GROUP BY i.i_item_id
  )
SELECT
  ci.i_item_id,
  cp.source,
  cp.sales_level,
  (SELECT COUNT(*) FROM store_sales WHERE ss_quantity > 0) AS total_store_transactions
FROM common_items ci
JOIN catalog_promo_items cp ON ci.i_item_id = cp.i_item_id
UNION ALL
SELECT
  i_item_id,
  source,
  sales_level,
  (SELECT COUNT(*) FROM store_sales WHERE ss_quantity > 0) AS total_store_transactions
FROM catalog_promo_items
ORDER BY i_item_id
LIMIT 100

WITH
  catalog_agg AS (
    SELECT
      cs.cs_order_number AS order_id,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS line_cnt,
      CONCAT('Catalog_', CAST(w.w_warehouse_id AS VARCHAR)) AS source_warehouse,
      REGEXP_EXTRACT(w.w_warehouse_name, '(\\w+)', 1) AS extra_info
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY cs.cs_order_number, w.w_warehouse_id, w.w_warehouse_name
  ),

  web_agg AS (
    SELECT
      ws.ws_order_number AS order_id,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS line_cnt,
      CONCAT('Web_', CAST(w.w_warehouse_id AS VARCHAR)) AS source_warehouse,
      REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)', 1) AS extra_info
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY ws.ws_order_number, w.w_warehouse_id, wp.wp_url
  ),

  -- Full outer join keeping rows that exist only on one side
  full_join AS (
    SELECT
      ca.order_id,
      ca.total_sales   AS catalog_sales,
      wa.total_sales   AS web_sales,
      ca.source_warehouse AS catalog_wh,
      wa.source_warehouse AS web_wh,
      ca.extra_info    AS catalog_info,
      wa.extra_info    AS web_info
    FROM catalog_agg ca
    FULL OUTER JOIN web_agg wa ON ca.order_id = wa.order_id
  ),

  -- Orders that appear in both returns tables (intersection)
  intersect_orders AS (
    SELECT cr.cr_order_number AS order_id
    FROM catalog_returns cr
    INTERSECT
    SELECT wr.wr_order_number AS order_id
    FROM web_returns wr
  ),

  -- Union of the two aggregation sources (distinct)
  union_set AS (
    SELECT order_id, total_sales, line_cnt, source_warehouse, extra_info
    FROM catalog_agg
    UNION
    SELECT order_id, total_sales, line_cnt, source_warehouse, extra_info
    FROM web_agg
  ),

  final AS (
    SELECT
      u.order_id,
      u.total_sales,
      u.line_cnt,
      u.source_warehouse,
      u.extra_info,
      lr.return_loss
    FROM union_set u
    -- Lateral subquery that calculates total net loss for the order from catalog_returns
    LEFT JOIN LATERAL (
      SELECT SUM(cr.cr_net_loss) AS return_loss
      FROM catalog_returns cr
      WHERE cr.cr_order_number = u.order_id
    ) lr ON TRUE
    WHERE u.extra_info IS NOT NULL
      AND REGEXP_LIKE(u.extra_info, '^\\w+')          -- string pattern check
      AND u.source_warehouse LIKE '%_%'               -- simple LIKE pattern
      AND u.order_id IN (SELECT order_id FROM intersect_orders)
  )

SELECT
  order_id,
  total_sales,
  line_cnt,
  source_warehouse,
  extra_info,
  return_loss
FROM final
ORDER BY total_sales DESC
LIMIT 100

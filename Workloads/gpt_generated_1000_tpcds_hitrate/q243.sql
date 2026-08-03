WITH
  store_agg AS (
    SELECT
      i.i_category,
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_category,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY
      i.i_category,
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END
  ),
  web_agg AS (
    SELECT
      i.i_category,
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_category,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
    GROUP BY
      i.i_category,
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END
  )
SELECT
  i_category,
  price_category,
  total_sales,
  distinct_orders
FROM store_agg
UNION
SELECT
  i_category,
  price_category,
  total_sales,
  distinct_orders
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100

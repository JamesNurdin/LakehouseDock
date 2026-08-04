WITH
  sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
  ),

  sub1 AS (
    SELECT ws.ws_order_number
    FROM sampled_ws ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '^.*[Aa]dvanced.*$')
      AND i.i_container LIKE '%Box%'
    GROUP BY ws.ws_order_number
    HAVING SUM(ws.ws_quantity) > 10
  ),

  sub2 AS (
    SELECT ws.ws_order_number
    FROM sampled_ws ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city LIKE 'New%'
      AND regexp_extract(w.w_street_name, '(\\w+)', 1) = 'Elm'
    GROUP BY ws.ws_order_number
    HAVING AVG(ws.ws_net_paid) > 100
  ),

  intersected AS (
    SELECT ws_order_number FROM sub1
    INTERSECT
    SELECT ws_order_number FROM sub2
  ),

  final AS (
    SELECT
      ws.ws_order_number,
      i.i_brand,
      i.i_category,
      COUNT(DISTINCT i.i_item_sk) AS distinct_items,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      CONCAT(i.i_brand, '-', i.i_category) AS brand_cat,
      (
        SELECT SUM(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number
      ) AS order_net_profit
    FROM sampled_ws ws
    JOIN intersected ix ON ws.ws_order_number = ix.ws_order_number
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
              AND wp2.wp_type = 'promo'
          )
      AND i.i_color LIKE 'Red%'
    GROUP BY ws.ws_order_number, i.i_brand, i.i_category
  )
SELECT
  ws_order_number,
  distinct_items,
  total_sales,
  brand_cat,
  order_net_profit
FROM final
ORDER BY total_sales DESC
LIMIT 100

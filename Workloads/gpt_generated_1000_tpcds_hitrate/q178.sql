WITH store_sales_agg AS (
  SELECT CONCAT(i.i_brand, ':', SUBSTRING(i.i_product_name, 1, 5)) AS brand_product,
         SUM(ss.ss_net_paid) AS total_sales
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE REGEXP_LIKE(i.i_product_name, '[A-Z]{3}')
    AND s.s_store_name LIKE '%Market%'
    AND t.t_am_pm = 'AM'
  GROUP BY CONCAT(i.i_brand, ':', SUBSTRING(i.i_product_name, 1, 5))
),
web_sales_agg AS (
  SELECT CONCAT(i.i_brand, ':', SUBSTRING(i.i_product_name, 1, 5)) AS brand_product,
         SUM(ws.ws_net_paid) AS total_sales
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE REGEXP_LIKE(i.i_product_name, '[0-9]{2}')
    AND w.w_warehouse_name LIKE '%Warehouse%'
    AND t.t_shift = 'night'
  GROUP BY CONCAT(i.i_brand, ':', SUBSTRING(i.i_product_name, 1, 5))
)
SELECT brand_product, total_sales
FROM (
  SELECT brand_product, total_sales FROM store_sales_agg
  UNION
  SELECT brand_product, total_sales FROM web_sales_agg
) u
ORDER BY total_sales DESC
LIMIT 100

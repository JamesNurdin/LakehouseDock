WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ws.ws_quantity > 0
)
SELECT
    i.i_category,
    wsite.web_name,
    regexp_extract(i.i_product_name, '([A-Z]{2}[0-9]{3})', 1) AS product_code,
    substring(i.i_product_name, 1, 10) AS product_prefix,
    SUM(fs.ws_net_profit) AS total_net_profit,
    SUM(fs.ws_quantity) AS total_quantity,
    COUNT(DISTINCT fs.ws_order_number) AS order_count
FROM filtered_sales fs
JOIN item i ON fs.ws_item_sk = i.i_item_sk
JOIN web_site wsite ON fs.ws_web_site_sk = wsite.web_site_sk
JOIN warehouse w ON fs.ws_warehouse_sk = w.w_warehouse_sk
WHERE wsite.web_name LIKE '%Online%'
  AND regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{3}')
  AND EXISTS (
      SELECT 1
      FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_quantity_on_hand > 1000
  )
GROUP BY
    i.i_category,
    wsite.web_name,
    regexp_extract(i.i_product_name, '([A-Z]{2}[0-9]{3})', 1),
    substring(i.i_product_name, 1, 10)
ORDER BY total_net_profit DESC
LIMIT 100

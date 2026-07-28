WITH sales_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_product_name, '[0-9]{2}')
    GROUP BY ws.ws_item_sk
),
inventory_stats AS (
    SELECT
        inv.inv_item_sk,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS distinct_warehouses
    FROM inventory inv
    JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND inv.inv_quantity_on_hand > 200
    GROUP BY inv.inv_item_sk
)
SELECT DISTINCT
    i.i_category,
    i.i_product_name,
    SUBSTRING(i.i_product_name, 1, 15) AS product_name_prefix,
    CONCAT(i.i_brand, '-', i.i_color) AS brand_color,
    s.total_profit,
    s.total_quantity,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
    ) AS avg_net_paid,
    invs.distinct_warehouses
FROM sales_agg s
JOIN item i ON s.ws_item_sk = i.i_item_sk
JOIN inventory_stats invs ON invs.inv_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_item_sk = i.i_item_sk
      AND wr.wr_return_quantity > 0
)
  AND i.i_category LIKE 'FURN%'
ORDER BY s.total_profit DESC
LIMIT 10

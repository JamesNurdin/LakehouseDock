WITH sampled_inventory AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
sales_items AS (
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category_id = 5
      AND ws.ws_net_profit > 0
),
returns_items AS (
    SELECT DISTINCT wr.wr_item_sk
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%defect%'
),
intersect_set AS (
    SELECT ws_item_sk FROM sales_items
    INTERSECT
    SELECT wr_item_sk FROM returns_items
),
except_set AS (
    SELECT ws_item_sk FROM sales_items
    EXCEPT
    SELECT wr_item_sk FROM returns_items
),
anti_sales AS (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_item_sk = ws.ws_item_sk
    )
),
union_set AS (
    SELECT ws_item_sk FROM sales_items
    UNION
    SELECT wr_item_sk FROM returns_items
)
SELECT
    i.i_item_id,
    i.i_product_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 'No Inventory' ELSE 'In Stock' END AS inventory_status,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN sampled_inventory inv ON i.i_item_sk = inv.inv_item_sk
WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM intersect_set)
  AND ws.ws_item_sk NOT IN (SELECT ws_item_sk FROM except_set)  -- demonstrate EXCEPT logic
  AND ws.ws_item_sk NOT IN (SELECT ws_item_sk FROM anti_sales) -- anti‑join example
GROUP BY i.i_item_id, i.i_product_name, inv.inv_quantity_on_hand
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY total_net_profit DESC
LIMIT 100

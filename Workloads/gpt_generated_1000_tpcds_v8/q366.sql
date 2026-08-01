WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
item_inventory AS (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_category,
           i.i_product_name,
           inv.inv_quantity_on_hand,
           w.w_warehouse_name
    FROM sampled_inventory inv
    FULL OUTER JOIN item i ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    brand,
    category,
    total_profit,
    sales_cnt,
    (SELECT AVG(ii.inv_quantity_on_hand)
     FROM item_inventory ii
     WHERE ii.i_brand = brand) AS avg_inventory_qty
FROM (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_brand, i.i_category

    UNION

    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_brand, i.i_category
) combined
ORDER BY total_profit DESC
OFFSET 0
LIMIT 100

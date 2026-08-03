WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    loc,
    COUNT(DISTINCT prod_id) AS distinct_product_cnt,
    COUNT(DISTINCT price)   AS distinct_price_cnt
FROM (
    SELECT
        i.i_item_id       AS prod_id,
        w.w_warehouse_name AS loc,
        inv.inv_quantity_on_hand AS qty,
        i.i_current_price AS price
    FROM sampled_inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND i.i_current_price > 20

    UNION ALL

    SELECT
        i2.i_item_id      AS prod_id,
        w2.w_warehouse_name AS loc,
        ws.ws_quantity    AS qty,
        ws.ws_sales_price AS price
    FROM web_sales ws
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_quantity > 0
      AND ws.ws_sales_price > 50
      AND td.t_hour BETWEEN 9 AND 17
) AS combined
GROUP BY loc
ORDER BY distinct_product_cnt DESC
LIMIT 100

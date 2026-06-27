WITH ws_item_sales AS (
    SELECT
        ws_warehouse_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS item_sales,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS item_profit
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_warehouse_sk, ws_item_sk
),
ranked_items AS (
    SELECT
        ws_warehouse_sk,
        ws_item_sk,
        item_sales,
        item_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_warehouse_sk ORDER BY item_sales DESC) AS sales_rank
    FROM ws_item_sales
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    r.ws_item_sk,
    r.item_sales,
    r.item_profit,
    r.sales_rank
FROM ranked_items r
JOIN warehouse w
    ON r.ws_warehouse_sk = w.w_warehouse_sk
WHERE r.sales_rank <= 5
ORDER BY w.w_warehouse_id, r.sales_rank

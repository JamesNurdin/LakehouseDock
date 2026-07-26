WITH latest_inv AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_warehouse_sk
),
hourly_sales AS (
    SELECT
        ws.ws_warehouse_sk,
        td.t_hour,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS hour_sales,
        COALESCE(li.total_inventory, 0) AS inventory_total,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 50000 THEN 'High' ELSE 'Normal' END AS sales_flag,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS hour_rank
    FROM web_sales ws
    INNER JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN latest_inv li ON ws.ws_warehouse_sk = li.inv_warehouse_sk
    GROUP BY ws.ws_warehouse_sk, td.t_hour, i.i_brand, li.total_inventory
)
SELECT
    ws_warehouse_sk,
    t_hour,
    i_brand,
    hour_sales,
    inventory_total,
    sales_flag,
    hour_rank
FROM hourly_sales
WHERE hour_rank <= 5
ORDER BY ws_warehouse_sk, hour_rank

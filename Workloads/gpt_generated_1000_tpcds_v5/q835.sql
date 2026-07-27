WITH base_sales AS (
    SELECT
        i.i_item_id,
        i.i_color,
        ca_store.ca_state,
        sm.sm_type,
        COALESCE(ss.ss_ext_sales_price, 0)          AS store_sales,
        COALESCE(ws.ws_ext_sales_price, 0)          AS web_sales,
        COALESCE(ss.ss_quantity, 0)                AS store_qty,
        COALESCE(ws.ws_quantity, 0)                AS web_qty,
        COALESCE(inv.inv_quantity_on_hand, 0)      AS inventory_qty
    FROM item i
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_store
        ON ca_store.ca_address_sk = ss.ss_addr_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_ship
        ON ca_ship.ca_address_sk = ws.ws_ship_addr_sk
    LEFT JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_color IN ('papaya', 'turquoise', 'moccasin', 'smoke', 'sandy')
        AND ca_store.ca_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND inv.inv_quantity_on_hand > 0
        AND i.i_current_price BETWEEN 10 AND 500
),
agg_sales AS (
    SELECT
        i_item_id,
        i_color,
        ca_state,
        sm_type,
        SUM(store_sales)                         AS total_store_sales,
        SUM(web_sales)                           AS total_web_sales,
        SUM(store_qty + web_qty)                 AS total_quantity,
        SUM(inventory_qty)                       AS total_inventory
    FROM base_sales
    GROUP BY i_item_id, i_color, ca_state, sm_type
)
SELECT *
FROM (
    SELECT
        i_item_id,
        i_color,
        ca_state,
        total_store_sales,
        total_web_sales,
        total_quantity,
        CASE WHEN total_store_sales > total_web_sales THEN 'Store' ELSE 'Web' END AS higher_channel,
        (total_store_sales + total_web_sales) / NULLIF(total_quantity, 0) AS avg_price_per_unit
    FROM agg_sales
    WHERE total_quantity > 20
    UNION ALL
    SELECT
        i_item_id,
        i_color,
        ca_state,
        total_store_sales,
        total_web_sales,
        total_quantity,
        CASE WHEN total_store_sales > total_web_sales THEN 'Store' ELSE 'Web' END,
        (total_store_sales + total_web_sales) / NULLIF(total_quantity, 0)
    FROM agg_sales
    WHERE (total_store_sales + total_web_sales) > 1000
          AND i_color = 'papaya'
          AND sm_type = 'AIR'
) AS combined
ORDER BY avg_price_per_unit DESC
LIMIT 100

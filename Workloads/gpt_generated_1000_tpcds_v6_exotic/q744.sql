WITH base_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        w.w_warehouse_name,
        w.w_state,
        p.p_promo_name,
        p.p_discount_active,
        td_cs.t_hour AS cs_hour,
        td_ws.t_hour AS ws_hour,
        cs.cs_net_profit,
        ws.ws_net_profit,
        cs.cs_quantity,
        ws.ws_quantity,
        inv.inv_quantity_on_hand,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        ws_site.web_country
    FROM catalog_sales cs
    JOIN time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    WHERE
        i.i_brand = 'Brand#23'               -- filter 1: specific brand
        AND w.w_state = 'CA'                  -- filter 2: warehouse state
        AND p.p_discount_active = 'Y'         -- filter 3: active promotion
        AND td_cs.t_hour BETWEEN 9 AND 17    -- filter 4: business hour
        AND inv.inv_quantity_on_hand > 50    -- filter 5: sufficient inventory
)
SELECT
    i_category,
    w_warehouse_name,
    SUM(cs_net_profit)               AS total_catalog_profit,
    SUM(ws_net_profit)               AS total_web_profit,
    SUM(cs_quantity)                 AS total_catalog_qty,
    SUM(ws_quantity)                 AS total_web_qty,
    SUM(inv_quantity_on_hand)        AS total_inventory_qty,
    SUM(wr_return_quantity)          AS total_return_qty,
    SUM(wr_net_loss)                 AS total_return_loss,
    ROW_NUMBER() OVER (
        PARTITION BY i_category
        ORDER BY SUM(cs_net_profit + ws_net_profit) DESC
    )                                 AS profit_rank,
    (
        SELECT DISTINCT p2.p_promo_name
        FROM promotion p2
        WHERE p2.p_discount_active = 'Y'
        LIMIT 1
    )                                 AS example_active_promo,
    (
        SELECT AVG(inv_sub.inv_quantity_on_hand)
        FROM inventory inv_sub
        JOIN item i_sub ON inv_sub.inv_item_sk = i_sub.i_item_sk
        WHERE i_sub.i_category = base_data.i_category
    )                                 AS avg_category_inventory
FROM base_data
GROUP BY
    GROUPING SETS (
        (i_category, w_warehouse_name),
        (i_category),
        (w_warehouse_name),
        ()
    )
ORDER BY
    profit_rank,
    i_category
LIMIT 100

/* Goal: Analyze combined catalog and web sales performance by warehouse, meal time and promotion status, including inventory availability and promotion item counts, with subtotals per dimension. */
WITH base AS (
    SELECT
        w.w_warehouse_name,
        td.t_meal_time,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_order_number,
        ws.ws_order_number,
        cs.cs_sales_price,
        cs.cs_quantity AS cs_qty,
        ws.ws_quantity AS ws_qty,
        (SELECT COUNT(DISTINCT p3.p_item_sk)
         FROM promotion p3
         WHERE p3.p_promo_sk = p.p_promo_sk) AS promo_item_count,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        td.t_meal_time = 'dinner'
        AND p.p_channel_press = 'N'
        AND w.w_county = 'Fairfield County'
        AND cs.cs_quantity > 5
        AND ws.ws_quantity > 3
        AND inv.inv_quantity_on_hand > 0
        AND NOT EXISTS (
            SELECT 1
            FROM inventory inv0
            WHERE inv0.inv_warehouse_sk = w.w_warehouse_sk
              AND inv0.inv_quantity_on_hand = 0
        )
)
SELECT
    w_warehouse_name,
    t_meal_time,
    promo_status,
    SUM(cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws_ext_sales_price) AS web_sales_amount,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws_order_number) AS web_orders,
    AVG(CASE WHEN cs_qty > 0 THEN cs_sales_price / cs_qty END) AS avg_catalog_price_per_item,
    MAX(promo_item_count) AS promo_item_count
FROM base
GROUP BY GROUPING SETS (
    (w_warehouse_name, t_meal_time, promo_status),
    (w_warehouse_name, promo_status),
    (t_meal_time, promo_status),
    (promo_status)
)
ORDER BY
    w_warehouse_name ASC,
    t_meal_time ASC,
    promo_status ASC
LIMIT 100

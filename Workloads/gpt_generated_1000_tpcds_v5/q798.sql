WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(COALESCE(sr.sr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        SUM(CASE WHEN wp.wp_max_ad_count > 2 THEN 1 ELSE 0 END) AS pages_with_many_ads
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450815 AND 2451179
        AND i.i_current_price > 10
        AND p.p_discount_active = 'Y'
        AND wp.wp_link_count >= 10
        AND w.w_warehouse_sq_ft > 50000
        AND EXISTS (
            SELECT 1 FROM reason r3
            WHERE r3.r_reason_sk = sr.sr_reason_sk
              AND r3.r_reason_desc LIKE '%Defect%'
        )
    GROUP BY
        i.i_item_id,
        i.i_category
)
SELECT
    i_category,
    SUM(total_net_profit) AS category_net_profit,
    AVG(total_return_qty) AS avg_return_qty_per_item,
    AVG(avg_inventory_on_hand) AS avg_inventory_on_hand,
    SUM(promo_count) AS total_promo_count,
    COUNT(*) AS num_items
FROM item_sales
GROUP BY i_category
HAVING
    SUM(total_net_profit) > 10000
    AND AVG(total_return_qty) < 5
    AND AVG(avg_inventory_on_hand) BETWEEN 100 AND 1000
ORDER BY category_net_profit DESC
LIMIT 100

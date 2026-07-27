WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    wsite.web_name,
    inv.total_qty_on_hand,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    COUNT(DISTINCT r.r_reason_desc) AS distinct_return_reasons,
    (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk) AS total_returns
FROM inv_agg inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    i.i_size = 'medium'
    AND s.s_state = 'CA'
    AND wsite.web_company_id = 1
    AND p.p_discount_active = 'Y'
    AND p.p_cost < 500
    AND i.i_current_price BETWEEN 50 AND 200
    AND EXISTS (
        SELECT 1 FROM web_returns wr_ex
        WHERE wr_ex.wr_item_sk = i.i_item_sk
          AND wr_ex.wr_net_loss > 0
    )
GROUP BY
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    wsite.web_name,
    inv.total_qty_on_hand,
    i.i_item_sk
HAVING
    SUM(ss.ss_net_profit) > 1000
    AND SUM(ws.ws_net_profit) > 1000
    AND inv.total_qty_on_hand > 200
ORDER BY
    store_sales_profit DESC
LIMIT 100

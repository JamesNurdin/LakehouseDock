WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cc.cc_name AS call_center_name,
    SUM(cs.cs_net_profit)                         AS total_catalog_profit,
    COALESCE(SUM(ws.ws_net_profit), 0)            AS total_web_profit,
    COALESCE(SUM(cr.cr_net_loss), 0)              AS total_return_loss,
    ia.total_on_hand,
    (SUM(cs.cs_net_profit) + COALESCE(SUM(ws.ws_net_profit), 0) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit,
    RANK() OVER (ORDER BY (SUM(cs.cs_net_profit) + COALESCE(SUM(ws.ws_net_profit), 0) - COALESCE(SUM(cr.cr_net_loss), 0)) DESC) AS profit_rank,
    CASE WHEN i.i_current_price > 20 THEN 'Premium' ELSE 'Standard' END AS price_category,
    (SELECT MAX(cc2.cc_employees) FROM call_center cc2) AS max_center_employees
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                              AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN inv_agg ia ON ia.inv_item_sk = i.i_item_sk
WHERE
    cc.cc_employees > 3000000
    AND cs.cs_ext_ship_cost > 500
    AND i.i_current_price BETWEEN 5 AND 30
    AND (ia.total_on_hand IS NULL OR ia.total_on_hand > 1000)
    AND ws.ws_quantity > 0
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cc.cc_name,
    ia.total_on_hand,
    i.i_current_price
HAVING
    (SUM(cs.cs_net_profit) + COALESCE(SUM(ws.ws_net_profit), 0) - COALESCE(SUM(cr.cr_net_loss), 0)) > 0
ORDER BY profit_rank
LIMIT 100

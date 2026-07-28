WITH
    total_returns AS (
        SELECT cr_item_sk,
               SUM(cr_return_amount) AS total_return_amount
        FROM catalog_returns
        GROUP BY cr_item_sk
    )
SELECT
    d_sales.d_year AS sales_year,
    i_ws.i_brand AS brand,
    i_ws.i_category AS category,
    p.p_promo_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    CASE
        WHEN SUM(ws.ws_net_profit) > 200000 THEN 'HIGH'
        WHEN SUM(ws.ws_net_profit) > 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    COALESCE(inv.inv_quantity_on_hand, 0) AS qty_on_hand,
    (
        SELECT MAX(tr.total_return_amount)
        FROM total_returns tr
        WHERE tr.cr_item_sk = i_ws.i_item_sk
    ) AS max_item_return
FROM web_sales ws
JOIN date_dim d_sales
  ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN item i_ws
  ON ws.ws_item_sk = i_ws.i_item_sk
LEFT JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = i_ws.i_item_sk
 AND cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i_ws.i_item_sk
 AND inv.inv_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
WHERE d_sales.d_year = 2001
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
GROUP BY
    d_sales.d_year,
    i_ws.i_brand,
    i_ws.i_category,
    p.p_promo_name,
    inv.inv_quantity_on_hand,
    i_ws.i_item_sk
ORDER BY total_net_profit DESC
LIMIT 100

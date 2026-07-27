WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_brand,
           i_category,
           i_current_price
    FROM   item
    WHERE  i_rec_start_date >= DATE '2000-01-01'
      AND  i_brand = 'BrandX'
)
SELECT
    cp.cp_catalog_page_id,
    i.i_item_id,
    i.i_brand,
    p.p_promo_name,
    SUM(cr.cr_return_amount)                         AS total_return_amount,
    AVG(ws.ws_net_profit)                            AS avg_net_profit,
    COUNT(DISTINCT ws.ws_order_number)               AS distinct_orders,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM   web_sales ws2
        WHERE  ws2.ws_sold_date_sk BETWEEN 2450 AND 2500
    )                                                AS overall_avg_profit
FROM   catalog_returns cr
JOIN   filtered_items i
       ON cr.cr_item_sk = i.i_item_sk
JOIN   catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN   web_sales ws
       ON ws.ws_item_sk = i.i_item_sk
JOIN   promotion p
       ON ws.ws_promo_sk = p.p_promo_sk
JOIN   web_returns wr
       ON wr.wr_item_sk = i.i_item_sk
      AND wr.wr_order_number = ws.ws_order_number
WHERE  cr.cr_returned_date_sk BETWEEN 2450 AND 2500
  AND  cr.cr_refunded_cash > 100.00
  AND  p.p_channel_event = 'N'
  AND  p.p_cost < 5000.00
  AND  ws.ws_quantity > 2
  AND EXISTS (
        SELECT 1
        FROM   (SELECT DISTINCT i_brand FROM item) ib
        WHERE  ib.i_brand = i.i_brand
    )
GROUP BY
    cp.cp_catalog_page_id,
    i.i_item_id,
    i.i_brand,
    p.p_promo_name
ORDER BY total_return_amount DESC
LIMIT 100

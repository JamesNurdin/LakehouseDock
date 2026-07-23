WITH inv_agg AS (
    SELECT inv_item_sk AS i_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_category,
    i.i_class,
    i.i_brand,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(ia.total_qty_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    MIN(ws.ws_sold_date_sk) AS first_sale_date_sk,
    MAX(ws.ws_sold_date_sk) AS last_sale_date_sk
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_customer_sk = c.c_customer_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN inv_agg ia ON i.i_item_sk = ia.i_item_sk
WHERE i.i_class_id IN (8, 16, 7)
  AND i.i_category_id = 10
  AND ws.ws_net_paid_inc_ship > 3000
  AND ws.ws_coupon_amt > 10
  AND wp.wp_image_count >= 4
  AND c.c_preferred_cust_flag = 'Y'
  AND r.r_reason_desc LIKE '%damaged%'
  AND ws.ws_ext_discount_amt > (SELECT AVG(ws2.ws_ext_discount_amt) FROM web_sales ws2)
GROUP BY i.i_category,
         i.i_class,
         i.i_brand,
         p.p_promo_name
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100

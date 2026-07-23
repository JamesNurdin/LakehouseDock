SELECT
    d_sales.d_year AS sales_year,
    p.p_promo_name,
    cc.cc_name,
    sm.sm_type,
    i.i_item_sk,
    i.i_product_name,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    AVG(i.i_current_price) AS avg_item_price,
    (SELECT AVG(cs2.cs_ext_discount_amt)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = i.i_item_sk) AS avg_catalog_discount_for_item
FROM catalog_sales cs
INNER JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
INNER JOIN time_dim t_sales
    ON cs.cs_sold_time_sk = t_sales.t_time_sk
INNER JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
INNER JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
INNER JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
INNER JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
INNER JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
WHERE d_sales.d_year = 2002
  AND p.p_discount_active = 'Y'
GROUP BY
    d_sales.d_year,
    p.p_promo_name,
    cc.cc_name,
    sm.sm_type,
    i.i_item_sk,
    i.i_product_name
ORDER BY total_catalog_net_paid DESC
LIMIT 100

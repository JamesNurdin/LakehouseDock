WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS order_count
    FROM web_sales ws
    GROUP BY
        ws.ws_web_site_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk
)
SELECT
    web.web_site_id,
    web.web_name,
    t.t_time AS time_of_day,
    t.t_meal_time,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    p.p_promo_name,
    c.c_customer_id,
    ca.ca_city,
    s.total_quantity,
    s.total_net_paid,
    CASE
        WHEN s.total_net_paid > 10000 THEN 'High'
        WHEN s.total_net_paid > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY web.web_site_id ORDER BY s.total_net_paid DESC) AS sales_rank_per_site,
    (SELECT MAX(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_returning_customer_sk = c.c_customer_sk) AS max_return_amount_for_customer
FROM sales_agg s
JOIN time_dim t ON s.ws_sold_time_sk = t.t_time_sk
JOIN catalog_returns cr ON t.t_time_sk = cr.cr_returned_time_sk
JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
JOIN web_site web ON s.ws_web_site_sk = web.web_site_sk
JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON s.ws_bill_addr_sk = ca.ca_address_sk
WHERE t.t_meal_time = 'lunch'
  AND web.web_company_name = 'anti'
  AND p.p_discount_active = 'Y'
  AND i.inv_quantity_on_hand > 0
  AND s.total_net_paid >= 500
ORDER BY s.total_net_paid DESC
LIMIT 100

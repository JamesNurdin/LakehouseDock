WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    w.w_warehouse_name,
    sm.sm_type,
    p.p_promo_name,
    t.t_hour,
    COUNT(DISTINCT cs.cs_order_number)   AS num_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number)   AS num_web_orders,
    SUM(cs.cs_ext_sales_price)           AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price)           AS total_web_sales,
    SUM(wr.wr_return_amt)                AS total_return_amount,
    inv_agg.total_on_hand
FROM catalog_sales cs
JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
-- Web sales linked through the same customer and item dimensions
JOIN web_sales ws             ON ws.ws_bill_customer_sk = c.c_customer_sk
                               AND ws.ws_item_sk = i.i_item_sk
                               AND ws.ws_warehouse_sk = w.w_warehouse_sk
                               AND ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site webs            ON ws.ws_web_site_sk = webs.web_site_sk
-- Returns linked to web sales via order number
LEFT JOIN web_returns wr      ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN inv_agg             ON inv_agg.inv_item_sk = i.i_item_sk
                               AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    cc.cc_company_name = 'ese'
    AND i.i_size = 'medium'
    AND w.w_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 9 AND 17
    AND t.t_am_pm = 'PM'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    w.w_warehouse_name,
    sm.sm_type,
    p.p_promo_name,
    t.t_hour,
    inv_agg.total_on_hand
ORDER BY total_web_sales DESC
LIMIT 100

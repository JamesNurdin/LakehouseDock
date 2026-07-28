SELECT
    d.d_year,
    i.i_category,
    SUM(cs.cs_net_paid)               AS total_catalog_sales,
    SUM(ws.ws_net_paid)               AS total_web_sales,
    SUM(ss.ss_net_paid)               AS total_store_sales,
    SUM(sr.sr_return_amt)             AS total_store_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(p.p_cost)                     AS avg_promo_cost,
    MAX(w.w_warehouse_sq_ft)          AS max_warehouse_size,
    (
        SELECT AVG(i2.i_wholesale_cost)
        FROM item i2
        WHERE i2.i_category = i.i_category
    )                                 AS avg_category_wholesale_cost
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
                 AND cs.cs_ship_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
                               AND cs.cs_ship_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
                        AND cs.cs_ship_addr_sk = ca.ca_address_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                    AND ss.ss_sold_time_sk = t.t_time_sk
                    AND ss.ss_item_sk = i.i_item_sk
                    AND ss.ss_customer_sk = c.c_customer_sk
                    AND ss.ss_cdemo_sk = cd.cd_demo_sk
                    AND ss.ss_addr_sk = ca.ca_address_sk
                    AND ss.ss_promo_sk = p.p_promo_sk
JOIN reason r ON r.r_reason_sk = r.r_reason_sk  -- placeholder to include the table (will be linked via store_returns)
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                      AND sr.sr_return_time_sk = t.t_time_sk
                      AND sr.sr_item_sk = i.i_item_sk
                      AND sr.sr_customer_sk = c.c_customer_sk
                      AND sr.sr_cdemo_sk = cd.cd_demo_sk
                      AND sr.sr_addr_sk = ca.ca_address_sk
                      AND sr.sr_reason_sk = r.r_reason_sk
                      AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_page wp ON wp.wp_web_page_sk = wp.wp_web_page_sk  -- placeholder to include the table (will be linked via web_sales)
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                    AND ws.ws_sold_time_sk = t.t_time_sk
                    AND ws.ws_item_sk = i.i_item_sk
                    AND ws.ws_bill_customer_sk = c.c_customer_sk
                    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
                    AND ws.ws_bill_addr_sk = ca.ca_address_sk
                    AND ws.ws_ship_customer_sk = c.c_customer_sk
                    AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
                    AND ws.ws_ship_addr_sk = ca.ca_address_sk
                    AND ws.ws_web_page_sk = wp.wp_web_page_sk
                    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                    AND ws.ws_warehouse_sk = w.w_warehouse_sk
                    AND ws.ws_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND p.p_discount_active = 'Y'
  AND cs.cs_quantity > 5
  AND ws.ws_net_paid > 1000
GROUP BY ROLLUP (d.d_year, i.i_category)
ORDER BY total_catalog_sales DESC, d.d_year NULLS LAST
LIMIT 100

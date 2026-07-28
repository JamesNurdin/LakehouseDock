WITH inventory_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    i_agg.total_quantity,
    cc.cc_name,
    p.p_promo_name,
    s.s_store_name,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT cs.cs_order_number)                         AS catalog_sales_orders,
    SUM(cs.cs_net_paid)                                        AS total_catalog_sales,
    SUM(cr.cr_return_amount)                                   AS total_catalog_returns,
    SUM(ws.ws_net_paid)                                        AS total_web_sales,
    SUM(sr.sr_return_amt)                                      AS total_store_returns,
    MIN(t_cs.t_hour)                                           AS earliest_sale_hour,
    MAX(t_cs.t_hour)                                           AS latest_sale_hour
FROM catalog_sales cs
JOIN time_dim t_cs               ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer c                  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd   ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib              ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca         ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN call_center cc              ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p                 ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w                 ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg i_agg         ON w.w_warehouse_sk = i_agg.inv_warehouse_sk
JOIN catalog_returns cr          ON cr.cr_order_number = cs.cs_order_number
                                   AND cr.cr_item_sk = cs.cs_item_sk
JOIN time_dim t_cr               ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN store_returns sr            ON sr.sr_customer_sk = c.c_customer_sk
JOIN time_dim t_sr               ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN store s                     ON sr.sr_store_sk = s.s_store_sk
JOIN customer_address ca_sr      ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN web_sales ws                ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN time_dim t_ws               ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_page wp                 ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site            ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE w.w_state = 'CA'
  AND t_cs.t_hour BETWEEN 9 AND 17
  AND ib.ib_lower_bound >= 50000
GROUP BY
    w.w_warehouse_name,
    i_agg.total_quantity,
    cc.cc_name,
    p.p_promo_name,
    s.s_store_name,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound

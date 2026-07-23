SELECT
    s.s_state AS store_state,
    p_cs.p_promo_name AS promo_name,
    ib.ib_income_band_sk AS income_band_sk,
    t.t_hour AS hour_of_day,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_return_amt_inc_tax) AS total_catalog_returns,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_returns,
    (SUM(cs.cs_quantity) + SUM(ss.ss_quantity) + SUM(ws.ws_quantity)) AS total_quantity_sold,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
FROM catalog_sales cs
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd_cs
    ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
JOIN household_demographics hd_cs
    ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
JOIN customer_address ca_cs
    ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_return_time_sk = t.t_time_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN customer_demographics cd_ws
    ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN household_demographics hd_ws
    ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN customer_address ca_ws
    ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
JOIN income_band ib
    ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND cd_cs.cd_gender = 'M'
  AND ib.ib_lower_bound >= 50000
GROUP BY s.s_state, p_cs.p_promo_name, ib.ib_income_band_sk, t.t_hour
HAVING (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid)) > 100000
ORDER BY SUM(cs.cs_net_paid) DESC

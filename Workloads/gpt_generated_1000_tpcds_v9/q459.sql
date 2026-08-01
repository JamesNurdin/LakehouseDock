SELECT
    cp.cp_department AS department,
    p_cs.p_promo_name AS promo_name,
    sm_cs.sm_type AS ship_mode_type,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
    (SELECT MAX(p_inner.p_cost) FROM promotion p_inner) AS max_promo_cost
FROM store_returns sr
JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = td_sr.t_time_sk
   AND cs.cs_bill_customer_sk = c_sr.c_customer_sk
   AND cs.cs_bill_addr_sk = ca_sr.ca_address_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN ship_mode sm_cs
    ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = td_sr.t_time_sk
   AND ws.ws_bill_customer_sk = c_sr.c_customer_sk
   AND ws.ws_bill_addr_sk = ca_sr.ca_address_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = td_sr.t_time_sk
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
WHERE cp.cp_department = 'Sports'
  AND cs.cs_item_sk IN (
        SELECT ws_sub.ws_item_sk
        FROM web_sales ws_sub
        WHERE ws_sub.ws_net_profit > 0
    )
GROUP BY cp.cp_department, p_cs.p_promo_name, sm_cs.sm_type
ORDER BY total_catalog_sales DESC
LIMIT 100

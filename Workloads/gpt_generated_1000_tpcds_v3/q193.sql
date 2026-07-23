SELECT
    s_ss.s_state AS store_state,
    CASE
        WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High'
        WHEN SUM(ss.ss_net_profit) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
FROM store_sales ss
JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s_ss ON ss.ss_store_sk = s_ss.s_store_sk
JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN store s_sr ON sr.sr_store_sk = s_sr.s_store_sk
JOIN income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
JOIN catalog_sales cs ON cs.cs_sold_time_sk = td_ss.t_time_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
JOIN household_demographics hd_cs_ship ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
JOIN customer_address ca_cs_bill ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
JOIN customer_address ca_cs_ship ON cs.cs_ship_addr_sk = ca_cs_ship.ca_address_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td_ss.t_time_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN income_band ib_wr_refunded ON hd_wr_refunded.hd_income_band_sk = ib_wr_refunded.ib_income_band_sk
GROUP BY
    s_ss.s_state
ORDER BY
    total_store_profit DESC
LIMIT 100

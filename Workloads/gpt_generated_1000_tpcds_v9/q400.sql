SELECT
    s.s_store_name,
    wsite.web_name,
    ds_ss.d_year AS sale_year,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions
FROM store_sales ss
JOIN date_dim ds_ss ON ss.ss_sold_date_sk = ds_ss.d_date_sk
JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
-- Store Returns and related dimensions
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim ds_sr ON sr.sr_returned_date_sk = ds_sr.d_date_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r_ret ON sr.sr_reason_sk = r_ret.r_reason_sk
-- Store closed date dimension
JOIN date_dim ds_store_closed ON s.s_closed_date_sk = ds_store_closed.d_date_sk
-- Promotion start/end dates (store promotion)
JOIN date_dim ds_p_start ON p_ss.p_start_date_sk = ds_p_start.d_date_sk
JOIN date_dim ds_p_end ON p_ss.p_end_date_sk = ds_p_end.d_date_sk
-- Web Sales and related dimensions
JOIN web_sales ws ON ws.ws_item_sk = i_ss.i_item_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN date_dim ds_ws_sold ON ws.ws_sold_date_sk = ds_ws_sold.d_date_sk
JOIN date_dim ds_ws_ship ON ws.ws_ship_date_sk = ds_ws_ship.d_date_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
-- Web Page date dimensions
JOIN date_dim ds_wp_creation ON wp.wp_creation_date_sk = ds_wp_creation.d_date_sk
JOIN date_dim ds_wp_access ON wp.wp_access_date_sk = ds_wp_access.d_date_sk
-- Web Site open/close date dimensions
JOIN date_dim ds_wsite_open ON wsite.web_open_date_sk = ds_wsite_open.d_date_sk
JOIN date_dim ds_wsite_close ON wsite.web_close_date_sk = ds_wsite_close.d_date_sk
-- Second alias for the item dimension (linked to web promotion)
JOIN item i_ws ON p_ws.p_item_sk = i_ws.i_item_sk
-- Web Returns and related dimensions
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i_ss.i_item_sk
JOIN date_dim ds_wr ON wr.wr_returned_date_sk = ds_wr.d_date_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
-- Promotion start/end dates (web promotion)
JOIN date_dim ds_p_ws_start ON p_ws.p_start_date_sk = ds_p_ws_start.d_date_sk
JOIN date_dim ds_p_ws_end ON p_ws.p_end_date_sk = ds_p_ws_end.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p_active
    WHERE p_active.p_item_sk = i_ss.i_item_sk
      AND p_active.p_discount_active = 'Y'
)
GROUP BY
    s.s_store_name,
    wsite.web_name,
    ds_ss.d_year
ORDER BY store_net_profit DESC
LIMIT 100

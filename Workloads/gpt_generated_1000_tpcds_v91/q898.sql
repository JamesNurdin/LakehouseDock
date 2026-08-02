SELECT
    s.s_store_name,
    d_sold.d_date,
    i.i_product_name,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(cs.cs_net_paid_inc_ship) AS catalog_net_paid,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    (
        SELECT SUM(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS total_store_profit,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY d_sold.d_date) AS row_num
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion promo_ss ON ss.ss_promo_sk = promo_ss.p_promo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN time_dim t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
JOIN call_center cc_cs ON cs.cs_call_center_sk = cc_cs.cc_call_center_sk
JOIN catalog_page cp_cs ON cs.cs_catalog_page_sk = cp_cs.cp_catalog_page_sk
JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN promotion promo_cs ON cs.cs_promo_sk = promo_cs.p_promo_sk
JOIN customer_address ca_cs_bill ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
JOIN customer_address ca_cs_ship ON cs.cs_ship_addr_sk = ca_cs_ship.ca_address_sk
JOIN date_dim d_cs_ship ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
JOIN time_dim t_cr_return ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
JOIN customer_address ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    AND sr.sr_item_sk = i.i_item_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
JOIN time_dim t_sr_return ON sr.sr_return_time_sk = t_sr_return.t_time_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN time_dim t_wr_return ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN web_site ws ON ws.web_open_date_sk = d_wr_return.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = promo_ss.p_promo_sk
      AND p2.p_discount_active = 'Y'
)
GROUP BY
    s.s_store_name,
    d_sold.d_date,
    i.i_product_name,
    s.s_store_sk
ORDER BY
    total_store_profit DESC,
    s.s_store_name
LIMIT 100

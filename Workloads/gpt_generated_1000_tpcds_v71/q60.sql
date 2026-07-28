SELECT
    i_cat.i_category AS item_category,
    ca_bs.ca_country AS customer_country,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(sr.sr_refunded_cash) AS total_store_refunded_cash,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(wp.wp_web_page_id) AS web_page_cnt,
    AVG(w.w_gmt_offset) AS avg_warehouse_gmt_offset
FROM
    catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer cust_bs ON cs.cs_bill_customer_sk = cust_bs.c_customer_sk
    JOIN customer_demographics cd_bs ON cs.cs_bill_cdemo_sk = cd_bs.cd_demo_sk
    JOIN household_demographics hd_bs ON cs.cs_bill_hdemo_sk = hd_bs.hd_demo_sk
    JOIN customer_address ca_bs ON cs.cs_bill_addr_sk = ca_bs.ca_address_sk
    JOIN customer cust_sh ON cs.cs_ship_customer_sk = cust_sh.c_customer_sk
    JOIN customer_demographics cd_sh ON cs.cs_ship_cdemo_sk = cd_sh.cd_demo_sk
    JOIN household_demographics hd_sh ON cs.cs_ship_hdemo_sk = hd_sh.hd_demo_sk
    JOIN customer_address ca_sh ON cs.cs_ship_addr_sk = ca_sh.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i_cat ON cs.cs_item_sk = i_cat.i_item_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN item i_cr ON cr.cr_item_sk = i_cr.i_item_sk
    JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i_store ON ss.ss_item_sk = i_store.i_item_sk
    JOIN customer cust_ss ON ss.ss_customer_sk = cust_ss.c_customer_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
    JOIN customer cust_sr ON sr.sr_customer_sk = cust_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i_cat.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = cust_bs.c_customer_sk
GROUP BY
    i_cat.i_category,
    ca_bs.ca_country
LIMIT 100

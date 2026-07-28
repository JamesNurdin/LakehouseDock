SELECT
    cc.cc_name AS call_center_name,
    t_sold.t_shift AS shift,
    SUM(ss.ss_net_profit)                AS store_net_profit,
    SUM(cs.cs_net_profit)                AS catalog_net_profit,
    SUM(ws.ws_net_profit)                AS web_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0))     AS store_return_loss,
    SUM(COALESCE(cr.cr_net_loss, 0))     AS catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0))     AS web_return_loss,
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)
        - SUM(COALESCE(sr.sr_net_loss, 0))
        - SUM(COALESCE(cr.cr_net_loss, 0))
        - SUM(COALESCE(wr.wr_net_loss, 0)) AS total_net_profit
FROM tpcds.store_sales ss
JOIN tpcds.time_dim t_sold
    ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN tpcds.customer_demographics cd_bill
    ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.household_demographics hd_bill
    ON ss.ss_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.customer_address ca_bill
    ON ss.ss_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.time_dim t_return_sr
    ON sr.sr_return_time_sk = t_return_sr.t_time_sk
JOIN tpcds.customer_demographics cd_ret
    ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN tpcds.household_demographics hd_ret
    ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN tpcds.customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN tpcds.catalog_sales cs
    ON 1 = 1
JOIN tpcds.time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN tpcds.time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN tpcds.web_sales ws
    ON 1 = 1
JOIN tpcds.time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
GROUP BY cc.cc_name, t_sold.t_shift
ORDER BY total_net_profit DESC

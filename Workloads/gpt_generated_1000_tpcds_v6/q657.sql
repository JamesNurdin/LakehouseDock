WITH avg_price_cte AS (
    SELECT avg(i_current_price) AS avg_price
    FROM tpcds.item
)
SELECT
    s.s_store_id,
    we.web_site_id,
    d_sales.d_year,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    CASE
        WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) > 1000000 THEN 'HIGH'
        WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) > 500000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) DESC) AS profit_rank,
    SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_profit
FROM
    tpcds.store_sales ss
JOIN tpcds.date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN tpcds.time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN tpcds.household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN tpcds.customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
JOIN tpcds.date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN tpcds.time_dim t_ws_sold
    ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN tpcds.date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN tpcds.ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer_demographics cd_ws_bill
    ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN tpcds.household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN tpcds.customer_address ca_ws_bill
    ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN tpcds.customer_demographics cd_ws_ship
    ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_ws_ship
    ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN tpcds.customer_address ca_ws_ship
    ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN tpcds.call_center cc
    ON cc.cc_closed_date_sk = d_return.d_date_sk
JOIN tpcds.date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN tpcds.catalog_page cp
    ON cp.cp_start_date_sk = d_sales.d_date_sk
JOIN tpcds.date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN tpcds.date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN tpcds.date_dim d_ws_open
    ON we.web_open_date_sk = d_ws_open.d_date_sk
JOIN tpcds.date_dim d_ws_close
    ON we.web_close_date_sk = d_ws_close.d_date_sk
JOIN tpcds.date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN tpcds.date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE
    i.i_current_price > (SELECT avg_price FROM avg_price_cte)
    AND d_sales.d_year = 2001
GROUP BY
    s.s_store_id,
    we.web_site_id,
    d_sales.d_year
ORDER BY
    total_profit DESC
LIMIT 100

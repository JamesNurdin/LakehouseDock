WITH wr_agg AS (
    SELECT
        wr_order_number,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    GROUP BY wr_order_number
)
SELECT
    d_ss.d_year,
    d_ss.d_month_seq,
    s.s_store_name,
    i.i_category,
    sm_cs.sm_type AS ship_type,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(cs.cs_net_profit) AS catalog_sales_profit,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    SUM(COALESCE(wr_agg.total_return_loss, 0)) AS total_return_loss,
    (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(COALESCE(wr_agg.total_return_loss, 0))) AS net_total
FROM store_sales ss
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
LEFT JOIN wr_agg ON ws.ws_order_number = wr_agg.wr_order_number
GROUP BY
    d_ss.d_year,
    d_ss.d_month_seq,
    s.s_store_name,
    i.i_category,
    sm_cs.sm_type
ORDER BY
    d_ss.d_year,
    d_ss.d_month_seq,
    s.s_store_name

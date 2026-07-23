WITH sales_agg AS (
    SELECT
        ws.ws_order_number AS ws_order_number,
        ws_site.web_name AS web_name,
        s.s_store_name AS s_store_name,
        d_date.d_year AS d_year,
        SUM(ws.ws_net_profit) AS total_ws_net_profit,
        SUM(cs.cs_net_profit) AS total_cs_net_profit,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
        SUM(ws.ws_net_profit) + SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS total_net_profit
    FROM
        catalog_sales cs
        JOIN date_dim d_date ON cs.cs_sold_date_sk = d_date.d_date_sk
        JOIN time_dim t_time ON cs.cs_sold_time_sk = t_time.t_time_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d_date.d_date_sk
                         AND ws.ws_sold_time_sk = t_time.t_time_sk
                         AND ws.ws_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN date_dim d_site_open ON ws_site.web_open_date_sk = d_site_open.d_date_sk
        JOIN date_dim d_site_close ON ws_site.web_close_date_sk = d_site_close.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d_date.d_date_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
        JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
        LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
        LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    WHERE
        d_date.d_year = 2001
        AND t_time.t_am_pm = 'PM'
        AND w.w_state = 'CA'
        AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
        AND cs.cs_ext_sales_price > 1000
    GROUP BY
        ws.ws_order_number,
        ws_site.web_name,
        s.s_store_name,
        d_date.d_year
)
SELECT
    ws_order_number,
    web_name,
    s_store_name,
    d_year,
    total_ws_net_profit,
    total_cs_net_profit,
    total_return_loss,
    total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100

WITH base AS (
    SELECT
        s.s_store_id,
        d.d_date,
        d.d_date_sk,
        sm.sm_ship_mode_id,
        sm.sm_ship_mode_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY d.d_date ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS store_sales_rank,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        (
            SELECT AVG(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_sold_date_sk = d.d_date_sk
              AND ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
        ) AS avg_web_sales_same_shipmode
    FROM date_dim d
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON s.s_store_sk = ss.ss_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
                         AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                       AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'PRIVATECARRIER'
      AND w.w_warehouse_sq_ft > 500000
    GROUP BY
        s.s_store_id,
        d.d_date,
        d.d_date_sk,
        sm.sm_ship_mode_id,
        sm.sm_ship_mode_sk
)
SELECT *
FROM base
ORDER BY total_sales DESC
LIMIT 100

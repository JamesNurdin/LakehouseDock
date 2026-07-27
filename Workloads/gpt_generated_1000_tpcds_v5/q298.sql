WITH sales_agg AS (
    SELECT
        ca_bill.ca_state AS bill_state,
        wsite.web_site_id,
        t.t_hour,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        CASE
            WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.20 THEN 'High'
            WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.10 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM web_sales ws
    INNER JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    INNER JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND ca_bill.ca_state = 'CA'
      AND wsite.web_country = 'United States'
      AND wp.wp_type = 'order'
      AND ws.ws_ext_tax > 10.00
      AND ws.ws_net_profit > 0
    GROUP BY ROLLUP (ca_bill.ca_state, wsite.web_site_id, t.t_hour)
)
SELECT
    bill_state,
    web_site_id,
    t_hour,
    total_sales,
    total_profit,
    order_cnt,
    profit_category,
    RANK() OVER (PARTITION BY bill_state ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY bill_state, profit_rank, t_hour
LIMIT 100

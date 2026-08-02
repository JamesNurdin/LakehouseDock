WITH base_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sales_price,
        ws.ws_quantity,
        d_sold.d_year,
        ca_bill.ca_state AS bill_state,
        sm.sm_type AS ship_type,
        sm.sm_carrier AS ship_carrier,
        wp.wp_type AS page_type,
        wp.wp_url
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer_address ca_bill
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year = 2000
      AND ca_bill.ca_state IN ('CA', 'TX', 'NY')
      AND sm.sm_type = 'AIR'
      AND ws.ws_sales_price > 50
)
SELECT
    bs.ws_order_number,
    bs.d_year,
    bs.bill_state,
    bs.ship_type,
    bs.ship_carrier,
    bs.page_type,
    bs.ws_net_profit,
    bs.ws_sales_price,
    CASE
        WHEN bs.ws_net_profit > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY bs.bill_state ORDER BY bs.ws_net_profit DESC) AS state_rank,
    SUM(bs.ws_net_profit) OVER (
        PARTITION BY bs.bill_state
        ORDER BY bs.ws_net_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_state_profit,
    u.url_segment
FROM base_sales bs
CROSS JOIN UNNEST(split(bs.wp_url, '/')) AS u(url_segment)
WHERE u.url_segment <> ''
ORDER BY bs.ws_net_profit DESC
LIMIT 100

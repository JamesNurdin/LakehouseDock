WITH sales_agg AS (
    SELECT
        ca_bill.ca_state AS billing_state,
        wp.wp_type AS page_type,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        ROUND(SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0), 4) AS profit_margin
    FROM web_sales ws
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk >= 2451545
      AND wp.wp_type = 'product'
      AND ws.ws_ext_discount_amt > 0
    GROUP BY ca_bill.ca_state, wp.wp_type
    HAVING SUM(ws.ws_ext_sales_price) > 10000
       AND COUNT(DISTINCT ws.ws_order_number) > 50
)
SELECT
    billing_state,
    page_type,
    order_cnt,
    total_sales,
    total_profit,
    avg_discount,
    profit_margin,
    RANK() OVER (PARTITION BY billing_state ORDER BY total_profit DESC) AS profit_rank_state
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100

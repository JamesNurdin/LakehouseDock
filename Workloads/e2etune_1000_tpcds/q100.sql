WITH sales_filtered AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS ext_discount_amt,
        ca_bill.ca_state AS bill_state,
        ws_site.web_mkt_class AS web_mkt_class
    FROM web_sales ws
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND wh.w_country = 'United States'
      AND ws_site.web_market_manager = 'John Doe'
      AND ca_ship.ca_state = ca_bill.ca_state
)
SELECT
    bill_state,
    web_mkt_class,
    order_cnt,
    total_net_paid,
    total_net_profit,
    avg_discount_amt,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        bill_state,
        web_mkt_class,
        COUNT(DISTINCT order_number) AS order_cnt,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        AVG(ext_discount_amt) AS avg_discount_amt
    FROM sales_filtered
    GROUP BY bill_state, web_mkt_class
    HAVING SUM(net_profit) > 10000
) t
ORDER BY total_net_profit DESC
LIMIT 50

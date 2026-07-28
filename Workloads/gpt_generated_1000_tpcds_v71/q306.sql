WITH joined AS (
    SELECT
        ca_bill.ca_county,
        ca_bill.ca_state,
        p.p_promo_name,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_date_sk
    FROM web_sales ws
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_wholesale_cost > 30
      AND ws.ws_net_paid_inc_tax BETWEEN 500 AND 5000
      AND p.p_channel_radio = 'N'
)
SELECT
    ca_county,
    ca_state,
    p_promo_name,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_profit,
    COUNT(*) AS order_cnt,
    MIN(ws_ship_date_sk) AS earliest_ship_date_sk,
    MAX(ws_ship_date_sk) AS latest_ship_date_sk
FROM joined
GROUP BY GROUPING SETS (
    (ca_county, ca_state, p_promo_name),
    (ca_county, ca_state),
    (p_promo_name),
    ()
)
ORDER BY total_sales DESC
LIMIT 100

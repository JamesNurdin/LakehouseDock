WITH sales_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_addr_sk,
        ws.ws_quantity,
        ws.ws_ext_list_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_ext_list_price > 1000
      AND ws.ws_quantity BETWEEN 2 AND 10
      AND ws.ws_net_paid > 500
)
SELECT
    COALESCE(ca.ca_state, 'UNKNOWN') AS customer_state,
    d.d_year,
    COUNT(DISTINCT sf.ws_order_number) AS order_cnt,
    SUM(sf.ws_net_profit) AS total_profit,
    AVG(sf.ws_net_profit) AS avg_profit,
    MIN(sf.ws_net_paid) AS min_paid,
    MAX(sf.ws_net_paid) AS max_paid,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_profit
FROM sales_filtered sf
INNER JOIN date_dim d
    ON sf.ws_sold_date_sk = d.d_date_sk
    AND d.d_year = 2002
    AND d.d_fy_week_seq IN (9, 13, 18)
LEFT JOIN customer_address ca
    ON sf.ws_bill_addr_sk = ca.ca_address_sk
    AND ca.ca_state = 'CA'
    AND ca.ca_zip IN ('75124', '86192')
GROUP BY
    COALESCE(ca.ca_state, 'UNKNOWN'),
    d.d_year
ORDER BY total_profit DESC
LIMIT 100

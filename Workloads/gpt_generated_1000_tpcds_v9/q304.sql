WITH joined_data AS (
    SELECT
        ca.ca_state,
        ws.ws_ship_mode_sk,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sales_price,
        cr.cr_return_tax,
        ca.ca_street_name
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sales_price > 30.00
      AND cr.cr_return_tax > 15.00
      AND ca.ca_street_name = 'Hill 7th'
)
SELECT
    ca_state,
    ws_ship_mode_sk,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(cr_return_amount) AS total_returns,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    AVG(ws_net_profit) AS avg_profit,
    MIN(ws_ext_sales_price) AS min_sales,
    MAX(ws_ext_sales_price) AS max_sales
FROM joined_data
GROUP BY CUBE (ca_state, ws_ship_mode_sk)
ORDER BY ca_state ASC NULLS LAST, ws_ship_mode_sk ASC NULLS LAST
LIMIT 100

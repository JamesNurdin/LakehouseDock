WITH high_return AS (
    SELECT cr_order_number, cr_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 2000
)
SELECT
    ca_refunded.ca_county,
    sm.sm_carrier,
    r.r_reason_desc,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_ext_sales_price) AS avg_sales_price,
    MIN(ws.ws_net_profit) AS min_net_profit,
    MAX(ws.ws_net_profit) AS max_net_profit
FROM catalog_returns cr
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_bill_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
WHERE
    ca_refunded.ca_county = 'Richland County'
    AND sm.sm_carrier = 'UPS'
    AND r.r_reason_id = 'AAAAAAAAADAAAAAAA'
    AND cr.cr_return_tax > 0
    AND EXISTS (
        SELECT 1 FROM high_return hr WHERE hr.cr_order_number = cr.cr_order_number
    )
GROUP BY
    ca_refunded.ca_county,
    sm.sm_carrier,
    r.r_reason_desc
HAVING
    SUM(cr.cr_return_amount) > 5000
ORDER BY
    total_return_amount DESC,
    orders_cnt DESC
LIMIT 100

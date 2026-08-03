WITH filtered_ws AS (
    SELECT ws.*
    FROM web_sales ws
    WHERE ws.ws_ship_addr_sk IN (
        SELECT ca.ca_address_sk
        FROM customer_address ca
        WHERE ca.ca_state LIKE 'N%'
    )
    AND ws.ws_net_profit > (
        SELECT MAX(cr.cr_net_loss)
        FROM catalog_returns cr
    )
)
SELECT
    ws.ws_order_number,
    ca.ca_address_id,
    ca.ca_street_number || ' ' || ca.ca_street_name || ', ' || ca.ca_city AS full_address,
    SUBSTRING(ca.ca_city, 1, 3) AS city_prefix,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'High' ELSE 'Low' END AS vehicle_indicator,
    CASE WHEN regexp_like(ca.ca_city, 'County$') THEN 1 ELSE 0 END AS is_county_city,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_order_number = ws.ws_order_number
    ) AS total_return_amount,
    ws.ws_net_paid_inc_ship
FROM filtered_ws ws
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE ca.ca_street_name LIKE '%Main%'
GROUP BY
    ws.ws_order_number,
    ca.ca_address_id,
    ca.ca_street_number,
    ca.ca_street_name,
    ca.ca_city,
    hd.hd_vehicle_count,
    ws.ws_net_paid_inc_ship
ORDER BY total_return_amount DESC
LIMIT 100

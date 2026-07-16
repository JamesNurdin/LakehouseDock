SELECT
    d.d_year,
    ca.ca_state,
    sm.sm_type,
    SUM(ws_sub.ws_net_paid) AS total_net_paid,
    COUNT(*) AS order_cnt
FROM (
    SELECT
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ws_bill_addr_sk,
        ws_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk = 2451506
) ws_sub
JOIN date_dim d
    ON ws_sub.ws_sold_date_sk = d.d_date_sk
JOIN customer_address ca
    ON ws_sub.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
    ON ws_sub.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ca.ca_state = 'MS'
  AND sm.sm_type = 'NEXT DAY                      '
GROUP BY d.d_year, ca.ca_state, sm.sm_type
HAVING SUM(ws_sub.ws_net_paid) > 2713.48

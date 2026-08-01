WITH overall_metrics AS (
    SELECT
        AVG(ws_net_paid) AS overall_avg_net_paid,
        SUM(ws_net_paid) AS overall_sum_net_paid
    FROM web_sales
),
billing_sales AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        'Billing' AS address_type,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
        MIN(ws.ws_net_paid) AS min_net_paid,
        MAX(ws.ws_net_paid) AS max_net_paid,
        (SELECT overall_avg_net_paid FROM overall_metrics) AS overall_avg_net_paid
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_location_type = 'condo'
      AND ca.ca_city IN ('Edgewood', 'Oakdale')
      AND ws.ws_net_paid > 1000
      AND ws.ws_coupon_amt < 500
      AND ws.ws_web_site_sk IN (
            SELECT ws2.ws_web_site_sk
            FROM web_sales ws2
            WHERE ws2.ws_net_paid > 2000
      )
    GROUP BY ca.ca_state, ca.ca_city
),
shipping_sales AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        'Shipping' AS address_type,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
        MIN(ws.ws_net_paid) AS min_net_paid,
        MAX(ws.ws_net_paid) AS max_net_paid,
        (SELECT overall_avg_net_paid FROM overall_metrics) AS overall_avg_net_paid
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ca.ca_location_type = 'single family'
      AND ca.ca_city IN ('Maple Grove', 'Fairview')
      AND ws.ws_net_paid > 1500
      AND ws.ws_coupon_amt < 300
      AND ws.ws_web_site_sk IN (
            SELECT ws2.ws_web_site_sk
            FROM web_sales ws2
            WHERE ws2.ws_net_paid > 2000
      )
    GROUP BY ca.ca_state, ca.ca_city
)
SELECT
    ca_state,
    ca_city,
    address_type,
    order_cnt,
    total_net_paid,
    avg_coupon_amt,
    min_net_paid,
    max_net_paid,
    overall_avg_net_paid
FROM billing_sales
UNION ALL
SELECT
    ca_state,
    ca_city,
    address_type,
    order_cnt,
    total_net_paid,
    avg_coupon_amt,
    min_net_paid,
    max_net_paid,
    overall_avg_net_paid
FROM shipping_sales
ORDER BY total_net_paid DESC
LIMIT 100

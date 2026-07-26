WITH customer_sales AS (
    SELECT
        ws.ws_bill_addr_sk AS address_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_net_paid) AS total_paid,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ws.ws_bill_addr_sk, ca.ca_city, ca.ca_state
),
customer_returns AS (
    SELECT
        cr.cr_refunded_addr_sk AS address_sk,
        SUM(cr.cr_return_amount) AS total_returned
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_addr_sk
)
SELECT
    cs.address_sk,
    cs.ca_city,
    cs.ca_state,
    cs.total_paid,
    COALESCE(cr.total_returned, 0) AS total_returned,
    cs.total_paid - COALESCE(cr.total_returned, 0) AS net_balance,
    CASE
        WHEN COALESCE(cr.total_returned, 0) > 0.1 * cs.total_paid THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_flag,
    cs.sales_rank
FROM customer_sales cs
LEFT JOIN customer_returns cr ON cs.address_sk = cr.address_sk
WHERE cs.sales_rank <= 5
ORDER BY cs.sales_rank

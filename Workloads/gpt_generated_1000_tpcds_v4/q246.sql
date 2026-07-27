WITH recent_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
)
SELECT *
FROM (
    SELECT
        c.c_customer_id AS customer_id,
        'Return' AS metric_type,
        SUM(sr.sr_return_amt) AS amount,
        CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS category
    FROM store_returns sr
    JOIN recent_dates rd ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id

    UNION ALL

    SELECT
        c.c_customer_id AS customer_id,
        'Sales' AS metric_type,
        SUM(ws.ws_ext_sales_price) AS amount,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS category
    FROM web_sales ws
    JOIN recent_dates rd ON ws.ws_sold_date_sk = rd.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
) combined
ORDER BY amount DESC
LIMIT 100

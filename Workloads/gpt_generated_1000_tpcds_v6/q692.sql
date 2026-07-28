WITH filtered_dates AS (
    SELECT
        d_date_sk,
        d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
)
SELECT
    sr.c_customer_id,
    sr.d_date,
    'store_return' AS source,
    sr.total_amount,
    CASE WHEN sr.total_amount > 1000 THEN 'High' ELSE 'Low' END AS category
FROM (
    SELECT
        c.c_customer_id,
        fd.d_date,
        SUM(sr.sr_net_loss) AS total_amount
    FROM store_returns sr
    JOIN filtered_dates fd ON sr.sr_returned_date_sk = fd.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, fd.d_date
) sr
UNION ALL
SELECT
    ws.c_customer_id,
    ws.d_date,
    'web_sale' AS source,
    ws.total_amount,
    CASE WHEN ws.total_amount > 1000 THEN 'High' ELSE 'Low' END AS category
FROM (
    SELECT
        c.c_customer_id,
        fd.d_date,
        SUM(ws.ws_net_profit) AS total_amount
    FROM web_sales ws
    JOIN filtered_dates fd ON ws.ws_sold_date_sk = fd.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, fd.d_date
) ws
ORDER BY total_amount DESC
LIMIT 100

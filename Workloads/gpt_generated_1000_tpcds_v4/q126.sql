WITH returns AS (
    SELECT DISTINCT
        c.c_customer_id,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_amt AS amount,
        'RETURN' AS activity_type
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2452300 AND 2452500
      AND cd.cd_credit_rating = 'Good'
),
web AS (
    SELECT DISTINCT
        c.c_customer_id,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_ext_sales_price AS amount,
        'WEB_SALE' AS activity_type
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2452300 AND 2452500
      AND cd.cd_credit_rating = 'Good'
)
SELECT
    activity_type,
    c_customer_id,
    date_sk,
    amount
FROM returns
UNION ALL
SELECT
    activity_type,
    c_customer_id,
    date_sk,
    amount
FROM web
ORDER BY amount DESC
LIMIT 100

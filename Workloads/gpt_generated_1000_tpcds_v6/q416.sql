WITH sales AS (
    SELECT
        ws.ws_web_site_sk,
        td.t_shift,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        (SELECT AVG(ws2.ws_ext_discount_amt)
         FROM web_sales ws2
         WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk) AS avg_discount,
        'sales' AS activity_type
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_web_site_sk IN (1, 2, 5)
    GROUP BY ws.ws_web_site_sk, td.t_shift
),
returns AS (
    SELECT
        ws.ws_web_site_sk,
        td.t_shift,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns,
        (SELECT AVG(ws2.ws_ext_discount_amt)
         FROM web_sales ws2
         WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk) AS avg_discount,
        'returns' AS activity_type
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = wr.wr_reason_sk
          AND r.r_reason_desc LIKE '%damaged%'
    )
    GROUP BY ws.ws_web_site_sk, td.t_shift
),
combined AS (
    SELECT ws_web_site_sk, t_shift, total_sales AS amount, avg_discount, activity_type
    FROM sales
    UNION ALL
    SELECT ws_web_site_sk, t_shift, total_returns AS amount, avg_discount, activity_type
    FROM returns
)
SELECT DISTINCT
    c.ws_web_site_sk,
    c.t_shift,
    c.activity_type,
    c.amount,
    c.avg_discount
FROM combined c
ORDER BY c.ws_web_site_sk, c.t_shift, c.activity_type

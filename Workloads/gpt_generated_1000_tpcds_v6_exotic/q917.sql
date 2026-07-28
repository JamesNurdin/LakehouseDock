WITH web_ret AS (
    SELECT
        d.d_date AS return_date,
        SUM(wr.wr_return_amt) AS total_return_amt,
        r.r_reason_desc AS reason_desc,
        'Web' AS source_type,
        (SELECT SUM(ws.ws_ext_sales_price)
         FROM web_sales ws
         JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2001) AS total_sales_2001
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
          AND wp.wp_type = 'home'
    )
    GROUP BY d.d_date, r.r_reason_desc
),
store_ret AS (
    SELECT
        d.d_date AS return_date,
        SUM(sr.sr_return_amt) AS total_return_amt,
        r.r_reason_desc AS reason_desc,
        'Store' AS source_type,
        (SELECT SUM(ws.ws_ext_sales_price)
         FROM web_sales ws
         JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2001) AS total_sales_2001
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY d.d_date, r.r_reason_desc
)
SELECT *
FROM (
    SELECT return_date, total_return_amt, reason_desc, source_type, total_sales_2001
    FROM web_ret
    UNION ALL
    SELECT return_date, total_return_amt, reason_desc, source_type, total_sales_2001
    FROM store_ret
) combined
ORDER BY return_date DESC, total_return_amt DESC
LIMIT 100

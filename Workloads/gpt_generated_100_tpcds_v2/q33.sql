WITH catalog_daily AS (
    SELECT d.d_date AS return_date,
           SUM(cr.cr_return_amount) AS total_return_amount,
           'Catalog' AS channel
    FROM tpcds.catalog_returns cr
    INNER JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-01-31'
    GROUP BY d.d_date
),
web_daily AS (
    SELECT d.d_date AS return_date,
           SUM(wr.wr_return_amt) AS total_return_amount,
           'Web' AS channel
    FROM tpcds.web_returns wr
    INNER JOIN tpcds.date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-01-31'
    GROUP BY d.d_date
)
SELECT return_date, total_return_amount, channel
FROM catalog_daily
UNION ALL
SELECT return_date, total_return_amount, channel
FROM web_daily
ORDER BY return_date, channel

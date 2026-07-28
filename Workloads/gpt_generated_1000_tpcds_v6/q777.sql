WITH catalog_agg AS (
    SELECT
        d.d_date AS return_date,
        ws.web_name AS site_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_date = DATE '1900-01-10'
      AND ws.web_tax_percentage = 0.07
      AND cr.cr_return_quantity > 1
    GROUP BY GROUPING SETS ((d.d_date, ws.web_name), (d.d_date), (ws.web_name), ())
),
web_agg AS (
    SELECT
        d.d_date AS return_date,
        ws.web_name AS site_name,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt,
        'web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
    WHERE d.d_date = DATE '1900-01-10'
      AND ws.web_tax_percentage = 0.07
      AND wr.wr_account_credit > 100
    GROUP BY GROUPING SETS ((d.d_date, ws.web_name), (d.d_date), (ws.web_name), ())
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
LIMIT 100

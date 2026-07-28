WITH catalog_monthly AS (
    SELECT
        r.r_reason_desc AS reason,
        CONCAT(CAST(d.d_year AS varchar), '-', LPAD(CAST(d.d_month_seq AS varchar), 2, '0')) AS year_month,
        SUM(cr.cr_return_amount) AS return_amount,
        'Catalog' AS source
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_class_id IN (7, 14)
    GROUP BY r.r_reason_desc, d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT
        r.r_reason_desc AS reason,
        CONCAT(CAST(d.d_year AS varchar), '-', LPAD(CAST(d.d_month_seq AS varchar), 2, '0')) AS year_month,
        SUM(wr.wr_return_amt) AS return_amount,
        'Web' AS source
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_class_id IN (7, 14)
    GROUP BY r.r_reason_desc, d.d_year, d.d_month_seq
),
combined_returns AS (
    SELECT reason, year_month, return_amount, source FROM catalog_monthly
    UNION ALL
    SELECT reason, year_month, return_amount, source FROM web_monthly
)
SELECT
    reason,
    year_month,
    SUM(return_amount) AS total_return_amount,
    SUM(CASE WHEN source = 'Catalog' THEN return_amount ELSE 0 END) AS catalog_return_amount,
    SUM(CASE WHEN source = 'Web' THEN return_amount ELSE 0 END) AS web_return_amount
FROM combined_returns
GROUP BY reason, year_month
ORDER BY total_return_amount DESC

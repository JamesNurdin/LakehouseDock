WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_returning_customer_sk,
        cr_returning_addr_sk,
        cr_reversed_charge,
        cr_order_number
    FROM catalog_returns
    WHERE cr_returning_addr_sk IN (5853988, 5312421)
      AND cr_reversed_charge > 50
      AND cr_return_amount > 0
),
date_filtered AS (
    SELECT
        d_date_sk,
        d_year,
        d_month_seq,
        d_following_holiday,
        d_dom
    FROM date_dim
    WHERE d_following_holiday = 'N'
      AND d_dom IN (8, 16, 21)
      AND d_year BETWEEN 1998 AND 2000
)
SELECT
    COALESCE(df.d_year, -1) AS year,
    COALESCE(df.d_month_seq, -1) AS month_seq,
    CASE
        WHEN fr.cr_return_amount >= 500 THEN 'High'
        WHEN fr.cr_return_amount >= 100 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    COUNT(fr.cr_order_number) AS num_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    MAX(fr.cr_return_quantity) AS max_return_quantity,
    MIN(fr.cr_return_quantity) AS min_return_quantity
FROM filtered_returns fr
FULL OUTER JOIN date_filtered df
    ON fr.cr_returned_date_sk = df.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_returning_customer_sk = fr.cr_returning_customer_sk
      AND cr2.cr_return_amount > 1000
)
GROUP BY
    COALESCE(df.d_year, -1),
    COALESCE(df.d_month_seq, -1),
    CASE
        WHEN fr.cr_return_amount >= 500 THEN 'High'
        WHEN fr.cr_return_amount >= 100 THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY
    year DESC,
    month_seq,
    total_return_amount DESC
LIMIT 100

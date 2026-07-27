WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_returning_cdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 20
      AND cr.cr_fee > 20
)
SELECT
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    CASE
        WHEN cr.cr_return_amount > 100 THEN 'High'
        ELSE 'Low'
    END AS return_category,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    MIN(cr.cr_return_quantity) AS min_quantity,
    MAX(cr.cr_return_quantity) AS max_quantity
FROM filtered_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_creation_date_sk = cr.cr_returned_date_sk
      AND wp.wp_max_ad_count = 2
      AND wp.wp_customer_sk IN (2907625, 1198376)
)
  AND d.d_year = 2000
  AND d.d_moy = 8
GROUP BY
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    CASE
        WHEN cr.cr_return_amount > 100 THEN 'High'
        ELSE 'Low'
    END
ORDER BY
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    return_category

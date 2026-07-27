WITH catalog_ret AS (
    SELECT
        'Catalog' AS source,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 1909
      AND r.r_reason_desc LIKE '%color%'
    GROUP BY r.r_reason_desc
),
store_ret AS (
    SELECT
        'Store' AS source,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 1909
      AND r.r_reason_desc LIKE '%color%'
    GROUP BY r.r_reason_desc
)
SELECT source,
       reason_desc,
       total_return_amount
FROM catalog_ret
UNION ALL
SELECT source,
       reason_desc,
       total_return_amount
FROM store_ret
ORDER BY source,
         total_return_amount DESC

WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT reason,
       total_return_amount,
       source
FROM (
    SELECT r.r_reason_desc AS reason,
           SUM(cr.cr_return_amount) AS total_return_amount,
           'Catalog' AS source
    FROM catalog_returns cr
    JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
    GROUP BY r.r_reason_desc

    UNION ALL

    SELECT r.r_reason_desc AS reason,
           SUM(sr.sr_return_amt) AS total_return_amount,
           'Store' AS source
    FROM store_returns sr
    JOIN recent_dates rd ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
    GROUP BY r.r_reason_desc
) combined
ORDER BY total_return_amount DESC
LIMIT 100

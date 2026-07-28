SELECT *
FROM (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(cr.cr_return_amount) AS total_return_amount,
           'catalog' AS source_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc
    UNION ALL
    SELECT r.r_reason_desc AS reason_desc,
           SUM(sr.sr_return_amt) AS total_return_amount,
           'store' AS source_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100

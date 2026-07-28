WITH catalog_data AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_qty,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_current_price BETWEEN 20 AND 100
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
),
store_data AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_quantity AS return_qty,
        'store' AS source
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_current_price BETWEEN 20 AND 100
      AND sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
    reason_desc,
    source,
    COUNT(*) AS return_records,
    SUM(return_amount) AS total_return_amount,
    SUM(return_qty) AS total_quantity
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
) AS combined
GROUP BY reason_desc, source
ORDER BY reason_desc, source

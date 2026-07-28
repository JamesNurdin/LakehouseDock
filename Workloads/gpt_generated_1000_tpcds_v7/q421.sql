WITH store_ret AS (
    SELECT 
        d.d_date AS return_date,
        i.i_item_id AS i_item_id,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_return_amt AS return_amount,
        'store' AS return_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_current_price > 100
),
catalog_ret AS (
    SELECT 
        d.d_date AS return_date,
        i.i_item_id AS i_item_id,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount,
        'catalog' AS return_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_current_price > 100
)
SELECT 
    return_date,
    i_item_id,
    return_quantity,
    return_amount,
    return_type
FROM store_ret
UNION ALL
SELECT 
    return_date,
    i_item_id,
    return_quantity,
    return_amount,
    return_type
FROM catalog_ret
ORDER BY return_date DESC
LIMIT 100

WITH catalog_sub AS (
    SELECT
        d.d_date AS return_date,
        cr.cr_return_amount AS return_amount,
        r.r_reason_desc AS reason_desc,
        cr.cr_item_sk AS item_sk,
        (
            SELECT COALESCE(SUM(i2.inv_quantity_on_hand), 0)
            FROM inventory i2
            WHERE i2.inv_item_sk = cr.cr_item_sk
        ) AS total_inventory_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
store_sub AS (
    SELECT
        d.d_date AS return_date,
        sr.sr_return_amt AS return_amount,
        r.r_reason_desc AS reason_desc,
        sr.sr_item_sk AS item_sk,
        (
            SELECT COALESCE(SUM(i2.inv_quantity_on_hand), 0)
            FROM inventory i2
            WHERE i2.inv_item_sk = sr.sr_item_sk
        ) AS total_inventory_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
)
SELECT return_date, return_amount, reason_desc, item_sk, total_inventory_qty
FROM catalog_sub
UNION ALL
SELECT return_date, return_amount, reason_desc, item_sk, total_inventory_qty
FROM store_sub
ORDER BY return_amount DESC, return_date ASC
LIMIT 100

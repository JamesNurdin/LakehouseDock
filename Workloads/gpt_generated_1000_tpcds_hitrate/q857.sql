WITH combined AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        i.i_item_id,
        i.i_category,
        cr.cr_return_amount AS return_amount,
        i.i_current_price,
        (
            SELECT avg(i3.i_current_price)
            FROM item i3
            WHERE i3.i_manufact_id = i.i_manufact_id
        ) AS avg_price_by_manu
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
              AND inv.inv_quantity_on_hand > 500
        )
    UNION
    SELECT
        sr.sr_returned_date_sk AS return_date_sk,
        i2.i_item_id,
        i2.i_category,
        sr.sr_return_amt AS return_amount,
        i2.i_current_price,
        (
            SELECT avg(i4.i_current_price)
            FROM item i4
            WHERE i4.i_manufact_id = i2.i_manufact_id
        ) AS avg_price_by_manu
    FROM store_returns sr
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND EXISTS (
            SELECT 1
            FROM inventory inv2
            WHERE inv2.inv_item_sk = i2.i_item_sk
              AND inv2.inv_quantity_on_hand > 500
        )
)
SELECT
    return_date_sk,
    i_item_id,
    i_category,
    SUM(return_amount) AS total_return_amount,
    CASE WHEN i_current_price > avg_price_by_manu THEN 'Above Avg'
         ELSE 'Below Avg'
    END AS price_category,
    ROW_NUMBER() OVER (ORDER BY SUM(return_amount) DESC) AS rn
FROM combined
GROUP BY
    return_date_sk,
    i_item_id,
    i_category,
    i_current_price,
    avg_price_by_manu
ORDER BY total_return_amount DESC
LIMIT 100

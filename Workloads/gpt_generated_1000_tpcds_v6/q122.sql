WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_class,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY sr.sr_return_amt DESC) AS rn
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE i.i_rec_end_date >= DATE '2000-01-01'
)
SELECT
    ir.i_item_id,
    ir.i_category,
    ir.i_class,
    ir.sr_return_amt,
    ir.ca_state,
    ir.rn,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ir.i_item_sk
    ) AS avg_return_amt_for_item
FROM item_returns ir
WHERE ir.i_category = 'accessories' AND ir.rn = 1

UNION ALL

SELECT
    ir.i_item_id,
    ir.i_category,
    ir.i_class,
    ir.sr_return_amt,
    ir.ca_state,
    ir.rn,
    (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ir.i_item_sk
    ) AS avg_return_amt_for_item
FROM item_returns ir
WHERE ir.i_class = 'maternity' AND ir.rn = 1

ORDER BY i_category, sr_return_amt DESC
LIMIT 100

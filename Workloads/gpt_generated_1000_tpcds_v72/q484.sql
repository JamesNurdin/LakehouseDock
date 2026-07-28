WITH high_cash AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        cr.cr_refunded_cash,
        i.i_manufact,
        i.i_category
    FROM catalog_returns AS cr
    JOIN item AS i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_refunded_cash > 200
      AND i.i_manufact_id IN (995, 630)
      AND i.i_rec_end_date = DATE '2000-10-26'
),
high_amount AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        cr.cr_return_amount,
        i.i_manufact,
        i.i_category
    FROM catalog_returns AS cr
    JOIN item AS i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 100
      AND i.i_category = 'Furniture'
      AND i.i_rec_end_date = DATE '2001-10-26'
)
SELECT
    returned_date_sk,
    order_number,
    metric_type,
    metric_value,
    manufact,
    category
FROM (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_order_number   AS order_number,
        'refunded_cash'      AS metric_type,
        cr.cr_refunded_cash  AS metric_value,
        i.i_manufact         AS manufact,
        i.i_category         AS category
    FROM catalog_returns AS cr
    JOIN item AS i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_refunded_cash > 200
      AND i.i_manufact_id IN (995, 630)
      AND i.i_rec_end_date = DATE '2000-10-26'
    UNION ALL
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        'return_amount',
        cr.cr_return_amount,
        i.i_manufact,
        i.i_category
    FROM catalog_returns AS cr
    JOIN item AS i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 100
      AND i.i_category = 'Furniture'
      AND i.i_rec_end_date = DATE '2001-10-26'
) AS combined
ORDER BY returned_date_sk DESC
LIMIT 100

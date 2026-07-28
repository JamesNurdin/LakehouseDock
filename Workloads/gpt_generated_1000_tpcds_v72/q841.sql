WITH cr_agg AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        AVG(cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_fee > 30.0
      AND cr_return_amount > 0
      AND cr_reversed_charge < 1000
      AND cr_store_credit IS NOT NULL
      AND cr_return_tax BETWEEN 0 AND 50
      AND cr_return_ship_cost >= 0
    GROUP BY cr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_wholesale_cost,
    i.i_units,
    cr_agg.total_return_amount,
    cr_agg.total_return_qty,
    cr_agg.avg_fee,
    cr_agg.return_cnt,
    cr_agg.total_return_amount / NULLIF(cr_agg.total_return_qty, 0) AS avg_return_per_qty
FROM cr_agg
JOIN item i
    ON cr_agg.cr_item_sk = i.i_item_sk
WHERE i.i_rec_end_date >= DATE '1999-01-01'
  AND i.i_rec_end_date <= DATE '2001-12-31'
  AND i.i_wholesale_cost BETWEEN 10 AND 50
  AND i.i_units IN ('Gram', 'Cup', 'Bunch')
  AND cr_agg.return_cnt > 5
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_refunded_hdemo_sk = 6661
    )
ORDER BY cr_agg.total_return_amount DESC
LIMIT 100

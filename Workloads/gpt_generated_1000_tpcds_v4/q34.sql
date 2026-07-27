WITH return_item_agg AS (
    SELECT
        cr.cr_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 50.00
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND cr.cr_store_credit BETWEEN 0.16 AND 500.00
      AND cr.cr_ship_mode_sk IN (2, 3, 9)
      AND cr.cr_returning_hdemo_sk NOT IN (848, 6206)
      AND i.i_wholesale_cost < 5.00
      AND i.i_formulation LIKE '%steel%'
    GROUP BY cr.cr_item_sk, i.i_item_id, i.i_product_name
)
SELECT
    rai.i_item_id,
    rai.i_product_name,
    rai.total_return_amount,
    rai.total_return_qty,
    rai.return_cnt,
    RANK() OVER (ORDER BY rai.total_return_amount DESC) AS amount_rank,
    DENSE_RANK() OVER (PARTITION BY rai.return_cnt ORDER BY rai.avg_return_tax DESC) AS tax_dense_rank
FROM return_item_agg rai
ORDER BY amount_rank
LIMIT 100

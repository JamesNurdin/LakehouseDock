WITH max_return AS (
    SELECT max(cr_return_amount) AS max_amount
    FROM catalog_returns
)
SELECT
    cr.cr_order_number,
    i.i_item_id,
    i.i_category,
    cp.cp_catalog_page_number,
    r.r_reason_desc,
    ti.t_meal_time,
    ib.ib_upper_bound,
    cr.cr_return_amount,
    CASE WHEN cr.cr_return_amount > (SELECT max_amount FROM max_return) THEN 'Highest' ELSE 'Normal' END AS amount_category,
    lr.total_qty,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cr.cr_return_amount DESC) AS category_rank
FROM
    catalog_returns AS cr
    TABLESAMPLE BERNOULLI (10)
    JOIN time_dim ti
        ON cr.cr_returned_time_sk = ti.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN LATERAL (
        SELECT sum(cr2.cr_return_quantity) AS total_qty
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
    ) lr ON true
WHERE
    ti.t_meal_time = 'lunch'
    AND i.i_class = 'shirts'
    AND cp.cp_type = 'monthly'
    AND ib.ib_upper_bound > 50000
    AND cr.cr_return_amount IS NOT NULL
ORDER BY
    cr.cr_return_amount DESC,
    category_rank
LIMIT 100

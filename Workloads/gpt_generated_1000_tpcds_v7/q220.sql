WITH cat_detail AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        sm.sm_carrier,
        SUM(cr.cr_return_amt_inc_tax) AS cat_sum
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amt_inc_tax > 1000
      AND i.i_category_id IN (5, 8)
      AND sm.sm_carrier = 'DHL'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        sm.sm_carrier
),
store_detail AS (
    SELECT
        i.i_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS store_sum
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_quantity >= 2
    GROUP BY i.i_item_sk
)
SELECT
    cd.i_item_id,
    cd.i_product_name,
    cd.i_category,
    cd.cat_sum,
    sd.store_sum,
    (cd.cat_sum + sd.store_sum) AS total_return_amount,
    RANK() OVER (PARTITION BY cd.i_category ORDER BY (cd.cat_sum + sd.store_sum) DESC) AS category_rank
FROM cat_detail cd
JOIN store_detail sd ON cd.i_item_sk = sd.i_item_sk
ORDER BY cd.i_category, category_rank
LIMIT 100

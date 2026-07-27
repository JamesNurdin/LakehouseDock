WITH high_qty AS (
    SELECT
        i.i_brand AS i_brand,
        cr.cr_return_amount AS cr_return_amount,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY cr.cr_return_amount DESC) AS brand_rank,
        cr.cr_order_number AS cr_order_number
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_quantity > 20
      AND i.i_class = 'infants'
      AND EXISTS (
          SELECT 1
          FROM item i2
          WHERE i2.i_brand = i.i_brand
            AND i2.i_formulation LIKE '%goldenrod%'
      )
),
specific_form AS (
    SELECT
        i.i_brand AS i_brand,
        cr.cr_return_amount AS cr_return_amount,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY cr.cr_return_amount DESC) AS brand_rank,
        cr.cr_order_number AS cr_order_number
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_formulation LIKE '1144670162goldenrod2%'
      AND cr.cr_call_center_sk IN (14, 32)
)
SELECT
    combined.i_brand,
    combined.cr_return_amount,
    combined.brand_rank,
    combined.cr_order_number
FROM (
    SELECT i_brand, cr_return_amount, brand_rank, cr_order_number FROM high_qty
    UNION ALL
    SELECT i_brand, cr_return_amount, brand_rank, cr_order_number FROM specific_form
) AS combined
WHERE combined.cr_return_amount > (
    SELECT AVG(cr_return_amount) FROM catalog_returns
)
ORDER BY combined.cr_return_amount DESC
LIMIT 100

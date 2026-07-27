WITH returns_by_item_year AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        COALESCE(i.i_units, 'UNKNOWN') AS item_units
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT OUTER JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
        AND d.d_dow IN (1, 2, 3, 4, 5)
        AND cr.cr_return_amount > 0
        AND cr.cr_return_quantity >= 1
        AND (i.i_container IS NULL OR i.i_container <> 'Unknown')
    GROUP BY i.i_item_id, d.d_year, COALESCE(i.i_units, 'UNKNOWN')
)
SELECT
    item_id,
    year,
    total_return_amount,
    total_return_qty,
    distinct_orders,
    item_units,
    total_return_amount / NULLIF(distinct_orders, 0) AS avg_return_amount_per_order
FROM (
    SELECT
        item_id,
        year,
        total_return_amount,
        total_return_qty,
        distinct_orders,
        item_units,
        ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY total_return_amount DESC) AS rn
    FROM returns_by_item_year
) t
WHERE rn = 1
    AND total_return_amount > 1000
    AND total_return_qty > 10
ORDER BY avg_return_amount_per_order DESC
LIMIT 100

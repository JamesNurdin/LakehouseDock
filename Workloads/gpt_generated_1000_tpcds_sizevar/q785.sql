WITH inv_sample AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
    WHERE inv_quantity_on_hand > 0
      AND inv_warehouse_sk IN (2, 3, 4)
      AND inv_item_sk BETWEEN 101400 AND 101500
),
date_filt AS (
    SELECT d_date_sk,
           d_date,
           d_day_name,
           d_year,
           d_following_holiday
    FROM date_dim
    WHERE d_day_name = 'Friday'
      AND d_following_holiday = 'N'
      AND d_year = 2002
),
intersect_items AS (
    SELECT inv_item_sk
    FROM inv_sample
    INTERSECT
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand < 100
)
SELECT
    d.d_date,
    i.inv_item_sk,
    i.inv_warehouse_sk,
    i.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY i.inv_item_sk ORDER BY d.d_date DESC) AS rn,
    CASE WHEN d.d_day_name = 'Friday' THEN 'Fri' ELSE d.d_day_name END AS day_label,
    u.val AS quantity_variant
FROM inv_sample i
RIGHT OUTER JOIN date_filt d
    ON i.inv_date_sk = d.d_date_sk
JOIN intersect_items ii
    ON i.inv_item_sk = ii.inv_item_sk
LEFT JOIN LATERAL (
    SELECT val
    FROM UNNEST(ARRAY[i.inv_quantity_on_hand, i.inv_quantity_on_hand + 10]) AS t(val)
) u ON true
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i2
    WHERE i2.inv_item_sk = i.inv_item_sk
      AND i2.inv_quantity_on_hand = 0
)
ORDER BY d.d_date DESC, rn
LIMIT 100

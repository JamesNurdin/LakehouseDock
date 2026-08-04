WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1300
      AND d_weekend = 'N'
      AND d_holiday = 'N'
),
joined AS (
    SELECT i.inv_item_sk,
           i.inv_warehouse_sk,
           i.inv_quantity_on_hand,
           d.d_date,
           d.d_year,
           d.d_month_seq,
           d.d_week_seq,
           ARRAY[i.inv_quantity_on_hand, i.inv_quantity_on_hand * 2] AS qty_arr
    FROM sampled_inventory i
    JOIN date_filtered d
      ON i.inv_date_sk = d.d_date_sk
),
unnested AS (
    SELECT j.inv_item_sk,
           j.inv_warehouse_sk,
           j.inv_quantity_on_hand,
           j.d_date,
           u.qty AS qty_value,
           ROW_NUMBER() OVER (PARTITION BY j.inv_item_sk ORDER BY j.inv_quantity_on_hand DESC) AS rn_item,
           RANK() OVER (ORDER BY j.inv_quantity_on_hand DESC) AS overall_rank,
           CASE WHEN j.inv_quantity_on_hand > 800 THEN 'HIGH' ELSE 'NORMAL' END AS qty_category
    FROM joined j
    CROSS JOIN UNNEST(j.qty_arr) AS u(qty)
),
scalar_comp AS (
    SELECT *
    FROM unnested
    WHERE inv_quantity_on_hand > (
        SELECT MAX(inv_quantity_on_hand)
        FROM inventory
        WHERE inv_item_sk = 101426
    )
)
SELECT inv_item_sk,
       inv_warehouse_sk,
       inv_quantity_on_hand,
       d_date,
       qty_value,
       rn_item,
       overall_rank,
       qty_category
FROM scalar_comp
UNION
SELECT inv_item_sk,
       inv_warehouse_sk,
       inv_quantity_on_hand,
       d_date,
       qty_value,
       rn_item,
       overall_rank,
       qty_category
FROM scalar_comp
WHERE overall_rank <= 5
ORDER BY overall_rank, inv_item_sk
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY

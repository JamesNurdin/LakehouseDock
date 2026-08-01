WITH filtered AS (
    SELECT inv.inv_date_sk,
           inv.inv_item_sk,
           inv.inv_quantity_on_hand,
           d.d_year,
           d.d_weekend,
           i.i_brand_id,
           i.i_formulation,
           SUBSTR(i.i_formulation, 1, 4) AS formulation_prefix,
           REGEXP_EXTRACT(i.i_formulation, '^([A-Za-z]+)', 1) AS alpha_prefix,
           CONCAT('Brand_', CAST(i.i_brand_id AS VARCHAR), '_', i.i_formulation) AS brand_form_concat,
           i.i_current_price
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_weekend = 'N'
      AND REGEXP_LIKE(i.i_formulation, '^.*[0-9]{4}$')
      AND i.i_formulation LIKE '%moccasin%'
),
agg AS (
    SELECT i_brand_id,
           formulation_prefix,
           d_year,
           SUM(inv_quantity_on_hand) AS total_qty,
           AVG(i_current_price) AS avg_price,
           COUNT(DISTINCT inv_date_sk) AS distinct_days
    FROM filtered
    GROUP BY i_brand_id, formulation_prefix, d_year
)
SELECT DISTINCT
       a.i_brand_id,
       a.formulation_prefix,
       a.d_year,
       a.total_qty,
       a.avg_price,
       a.distinct_days,
       (SELECT COALESCE(SUM(f2.inv_quantity_on_hand), 0)
        FROM filtered f2
        WHERE f2.i_brand_id = a.i_brand_id
          AND f2.formulation_prefix = a.formulation_prefix
          AND f2.d_year = a.d_year - 1) AS prior_year_qty
FROM agg a
WHERE a.total_qty > 0
ORDER BY a.total_qty DESC
LIMIT 100

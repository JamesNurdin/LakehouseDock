WITH inv_agg AS (
    SELECT
        d.d_fy_year,
        d.d_qoy AS fiscal_quarter,
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_fy_year BETWEEN 1900 AND 1902
    GROUP BY d.d_fy_year, d.d_qoy, i.inv_warehouse_sk
),
promo_agg AS (
    SELECT
        d.d_fy_year,
        d.d_qoy AS fiscal_quarter,
        SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d.d_fy_year BETWEEN 1900 AND 1902
    GROUP BY d.d_fy_year, d.d_qoy
)
SELECT
    i.d_fy_year,
    i.fiscal_quarter,
    i.inv_warehouse_sk,
    i.total_quantity,
    COALESCE(p.total_promo_cost, 0) AS total_promo_cost,
    CASE WHEN COALESCE(p.total_promo_cost, 0) = 0 THEN NULL
         ELSE CAST(i.total_quantity AS DOUBLE) / COALESCE(p.total_promo_cost, 0)
    END AS quantity_per_cost_ratio,
    RANK() OVER (PARTITION BY i.d_fy_year, i.fiscal_quarter ORDER BY i.total_quantity DESC) AS warehouse_rank
FROM inv_agg i
LEFT JOIN promo_agg p
  ON i.d_fy_year = p.d_fy_year
 AND i.fiscal_quarter = p.fiscal_quarter
WHERE i.total_quantity > 1000
ORDER BY i.d_fy_year, i.fiscal_quarter, warehouse_rank
LIMIT 100

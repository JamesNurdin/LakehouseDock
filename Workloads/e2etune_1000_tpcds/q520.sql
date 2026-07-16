WITH monthly_category_stats AS (
    SELECT
        d_inv.d_year AS year,
        d_inv.d_moy AS month,
        it.i_category AS category,
        hd.hd_income_band_sk AS income_band,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
        AVG(p.p_cost) AS avg_promo_cost,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item it ON inv.inv_item_sk = it.i_item_sk
    JOIN promotion p ON it.i_item_sk = p.p_item_sk
    JOIN date_dim d_promo ON p.p_start_date_sk = d_promo.d_date_sk
    JOIN customer c ON c.c_first_sales_date_sk = d_promo.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE d_inv.d_year = 2022
      AND d_promo.d_year = 2022
      AND it.i_category = 'Books'
      AND hd.hd_income_band_sk BETWEEN 3 AND 6
      AND p.p_discount_active = 'Y'
    GROUP BY d_inv.d_year, d_inv.d_moy, it.i_category, hd.hd_income_band_sk
)
SELECT
    year,
    month,
    category,
    income_band,
    total_qty_on_hand,
    avg_promo_cost,
    promo_count,
    RANK() OVER (PARTITION BY year, month ORDER BY total_qty_on_hand DESC) AS qty_rank
FROM monthly_category_stats
ORDER BY year, month, qty_rank

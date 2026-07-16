WITH cp_monthly AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        COUNT(cp.cp_catalog_page_sk) AS catalog_page_cnt
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_type = 'monthly'
    GROUP BY d.d_year, d.d_moy
),
promo_monthly AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost,
        COUNT(p.p_promo_sk) AS promo_cnt
    FROM promotion p
    JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_cost > 0
    GROUP BY d.d_year, d.d_moy
),
store_closed_monthly AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        SUM(s.s_floor_space) AS closed_store_floor_space,
        COUNT(s.s_store_sk) AS closed_store_cnt
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_moy
)
SELECT
    cp.d_year,
    cp.month,
    cp.catalog_page_cnt,
    pm.total_promo_cost,
    pm.avg_promo_cost,
    sm.closed_store_floor_space,
    sm.closed_store_cnt,
    RANK() OVER (ORDER BY pm.total_promo_cost DESC) AS promo_cost_rank
FROM cp_monthly cp
LEFT JOIN promo_monthly pm
    ON cp.d_year = pm.d_year AND cp.month = pm.month
LEFT JOIN store_closed_monthly sm
    ON cp.d_year = sm.d_year AND cp.month = sm.month
ORDER BY promo_cost_rank
LIMIT 10

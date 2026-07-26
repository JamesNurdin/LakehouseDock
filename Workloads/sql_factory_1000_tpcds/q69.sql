WITH promo_demo_cost AS (
    SELECT
        hd.hd_buy_potential,
        ds.d_year AS promo_year,
        SUM(p.p_cost) AS total_cost
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_buy_potential, ds.d_year
)
SELECT
    hd_buy_potential,
    promo_year,
    total_cost,
    cost_rank
FROM (
    SELECT
        hd_buy_potential,
        promo_year,
        total_cost,
        RANK() OVER (PARTITION BY promo_year ORDER BY total_cost DESC) AS cost_rank
    FROM promo_demo_cost
) ranked
WHERE cost_rank <= 3
ORDER BY promo_year, cost_rank

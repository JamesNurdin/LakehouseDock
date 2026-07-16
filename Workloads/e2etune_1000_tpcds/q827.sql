WITH promo_cp AS (
    SELECT
        cp.cp_department AS department,
        d_cp.d_year AS year,
        d_cp.d_moy AS month,
        hd.hd_buy_potential AS buy_potential,
        COUNT(DISTINCT c.c_customer_id) AS num_customers,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS num_catalog_pages,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost_per_page
    FROM
        catalog_page cp
        JOIN date_dim d_cp ON cp.cp_start_date_sk = d_cp.d_date_sk
        JOIN promotion p ON p.p_start_date_sk <= cp.cp_end_date_sk
                         AND p.p_end_date_sk >= cp.cp_start_date_sk
        JOIN customer c ON c.c_first_sales_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        cp.cp_type = 'monthly'
        AND p.p_channel_email = 'Y'
        AND hd.hd_buy_potential = 'high'
        AND d_cp.d_year = 2022
    GROUP BY
        cp.cp_department,
        d_cp.d_year,
        d_cp.d_moy,
        hd.hd_buy_potential
)
SELECT
    *,
    RANK() OVER (PARTITION BY year, month ORDER BY total_promo_cost DESC) AS dept_rank
FROM promo_cp
ORDER BY total_promo_cost DESC
LIMIT 100

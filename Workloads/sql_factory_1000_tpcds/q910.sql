WITH channel_costs AS (
    SELECT
        ds.d_year,
        hd.hd_buy_potential,
        'Email' AS channel,
        AVG(p.p_cost) AS avg_cost,
        SUM(p.p_cost) AS total_cost
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ds.d_holiday = 'Y' AND ds.d_month_seq BETWEEN 20201 AND 20212
    GROUP BY ds.d_year, hd.hd_buy_potential
    UNION ALL
    SELECT
        ds.d_year,
        hd.hd_buy_potential,
        'TV' AS channel,
        AVG(p.p_cost) AS avg_cost,
        SUM(p.p_cost) AS total_cost
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ds.d_holiday = 'Y' AND ds.d_month_seq BETWEEN 20201 AND 20212
    GROUP BY ds.d_year, hd.hd_buy_potential
)
SELECT
    d_year,
    hd_buy_potential,
    channel,
    avg_cost,
    total_cost,
    PERCENT_RANK() OVER (PARTITION BY d_year ORDER BY total_cost DESC) AS cost_percentile,
    ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY avg_cost ASC) AS asc_rank
FROM channel_costs
WHERE avg_cost IS NOT NULL
ORDER BY d_year, cost_percentile DESC

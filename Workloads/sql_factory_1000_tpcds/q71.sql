WITH channel_costs AS (
    SELECT
        ds.d_year,
        hd.hd_buy_potential,
        'Email' AS channel,
        AVG(CASE WHEN p.p_channel_email = 'Y' THEN p.p_cost END) AS avg_cost
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ds.d_holiday = 'Y'
    GROUP BY ds.d_year, hd.hd_buy_potential
    UNION ALL
    SELECT
        ds.d_year,
        hd.hd_buy_potential,
        'TV' AS channel,
        AVG(CASE WHEN p.p_channel_tv = 'Y' THEN p.p_cost END) AS avg_cost
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ds.d_holiday = 'Y'
    GROUP BY ds.d_year, hd.hd_buy_potential
    UNION ALL
    SELECT
        ds.d_year,
        hd.hd_buy_potential,
        'Catalog' AS channel,
        AVG(CASE WHEN p.p_channel_catalog = 'Y' THEN p.p_cost END) AS avg_cost
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ds.d_holiday = 'Y'
    GROUP BY ds.d_year, hd.hd_buy_potential
    UNION ALL
    SELECT
        ds.d_year,
        hd.hd_buy_potential,
        'Radio' AS channel,
        AVG(CASE WHEN p.p_channel_radio = 'Y' THEN p.p_cost END) AS avg_cost
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ds.d_holiday = 'Y'
    GROUP BY ds.d_year, hd.hd_buy_potential
)
SELECT
    d_year,
    hd_buy_potential,
    channel,
    avg_cost,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY avg_cost DESC) AS channel_rank
FROM channel_costs
WHERE avg_cost IS NOT NULL
ORDER BY d_year, channel_rank

WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_current_hdemo_sk,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day,
        c.c_current_addr_sk,
        c.c_preferred_cust_flag,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND c.c_current_addr_sk IN (4417012, 5089185, 338968)
      AND hd.hd_dep_count <= 2
      AND ib.ib_lower_bound >= 60000
),
agg_income AS (
    SELECT
        b.hd_income_band_sk AS ib_income_band_sk,
        COUNT(DISTINCT b.c_customer_sk) AS customer_cnt,
        AVG(b.ib_upper_bound - b.ib_lower_bound) AS avg_band_width,
        COUNT(DISTINCT CASE WHEN b.hd_buy_potential LIKE '>%' THEN b.c_customer_sk END) AS high_buy_potential_cnt
    FROM base b
    GROUP BY b.hd_income_band_sk
    HAVING COUNT(DISTINCT b.c_customer_sk) >= 100
)
SELECT
    a.ib_income_band_sk,
    a.customer_cnt,
    a.avg_band_width,
    a.high_buy_potential_cnt,
    (SELECT MAX(ib.ib_upper_bound)
       FROM tpcds.income_band ib
       WHERE ib.ib_income_band_sk = a.ib_income_band_sk) AS max_upper_bound
FROM agg_income a
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.household_demographics hd
    WHERE hd.hd_income_band_sk = a.ib_income_band_sk
      AND hd.hd_buy_potential = 'Unknown'
)
ORDER BY a.customer_cnt DESC, a.ib_income_band_sk

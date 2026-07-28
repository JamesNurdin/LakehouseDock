WITH filtered AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        CASE
            WHEN hd.hd_income_band_sk >= 10 THEN 'High'
            ELSE 'Low'
        END AS income_category
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_month BETWEEN 5 AND 7
      AND c.c_birth_year >= 1980
      AND hd.hd_buy_potential IN ('>10000', '5001-10000')
      AND hd.hd_dep_count <= 2
),
agg AS (
    SELECT
        income_category,
        COUNT(*) AS cust_cnt
    FROM filtered
    GROUP BY income_category
)
SELECT
    income_category,
    cust_cnt,
    RANK() OVER (ORDER BY cust_cnt DESC) AS rank_by_cnt,
    SUM(cust_cnt) OVER () AS total_customers
FROM agg
ORDER BY rank_by_cnt
LIMIT 100

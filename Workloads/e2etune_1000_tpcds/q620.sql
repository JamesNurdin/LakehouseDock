WITH cust_web AS (
    SELECT
        w.web_market_manager,
        ib.ib_income_band_sk,
        c.c_preferred_cust_flag,
        c.c_customer_sk,
        c.c_birth_year,
        w.web_gmt_offset
    FROM
        customer c
    JOIN
        web_site w
        ON c.c_birth_country = w.web_country
    JOIN
        income_band ib
        ON CAST(w.web_gmt_offset * 1000 AS INTEGER) BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_year BETWEEN 1960 AND 2000
        AND w.web_open_date_sk >= 20200101
),
agg AS (
    SELECT
        web_market_manager,
        ib_income_band_sk,
        c_preferred_cust_flag,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        AVG(c_birth_year) AS avg_birth_year,
        SUM(web_gmt_offset) AS total_gmt_offset
    FROM
        cust_web
    GROUP BY
        web_market_manager,
        ib_income_band_sk,
        c_preferred_cust_flag
    HAVING
        COUNT(DISTINCT c_customer_sk) >= 5
)
SELECT
    web_market_manager,
    ib_income_band_sk,
    c_preferred_cust_flag,
    num_customers,
    avg_birth_year,
    total_gmt_offset,
    RANK() OVER (ORDER BY num_customers DESC) AS manager_income_rank
FROM
    agg
ORDER BY
    total_gmt_offset DESC
LIMIT 20

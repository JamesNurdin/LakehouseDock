WITH per_customer AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        ds.d_date AS shipto_date,
        df.d_date AS sales_date,
        date_diff('day', ds.d_date, df.d_date) AS days_between,
        c.c_last_review_date
    FROM
        customer c
        JOIN date_dim ds ON c.c_first_shipto_date_sk = ds.d_date_sk
        JOIN date_dim df ON c.c_first_sales_date_sk = df.d_date_sk
    WHERE
        ds.d_year = 1998
        AND df.d_year = 1998
        AND c.c_birth_year BETWEEN 1950 AND 1970
        AND c.c_last_review_date > 2452000
),
agg_preferred AS (
    SELECT
        pc.c_birth_year AS birth_year,
        AVG(pc.days_between) AS avg_days_between,
        COUNT(DISTINCT pc.c_customer_id) AS distinct_customers
    FROM per_customer pc
    WHERE pc.c_preferred_cust_flag = 'Y'
    GROUP BY pc.c_birth_year
),
agg_non_preferred AS (
    SELECT
        pc.c_birth_year AS birth_year,
        AVG(pc.days_between) AS avg_days_between,
        COUNT(DISTINCT pc.c_customer_id) AS distinct_customers
    FROM per_customer pc
    WHERE pc.c_preferred_cust_flag = 'N'
    GROUP BY pc.c_birth_year
),
union_agg AS (
    SELECT * FROM agg_preferred
    UNION
    SELECT * FROM agg_non_preferred
)
SELECT
    birth_year,
    avg_days_between,
    distinct_customers
FROM union_agg
WHERE distinct_customers >= 5
ORDER BY avg_days_between DESC
LIMIT 100

WITH date_agg AS (
    SELECT
        d_year,
        d_quarter_name,
        COUNT(*) AS num_dates,
        MAX(d_date) AS max_date
    FROM date_dim
    WHERE d_year = 2002
      AND d_quarter_seq = 15
    GROUP BY d_year, d_quarter_name
)
SELECT
    c.c_salutation,
    c.c_birth_month,
    d_agg.d_quarter_name,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(c.c_birth_day) AS avg_birth_day,
    MIN(c.c_birth_year) AS min_birth_year,
    MAX(c.c_birth_year) AS max_birth_year,
    d_agg.num_dates,
    d_agg.max_date,
    (
        SELECT COUNT(*)
        FROM customer c2
        WHERE c2.c_salutation = c.c_salutation
          AND c2.c_birth_month = 7
    ) AS same_salutation_birthmonth_cnt
FROM customer c
JOIN date_dim d
    ON c.c_first_sales_date_sk = d.d_date_sk
JOIN date_agg d_agg
    ON d.d_year = d_agg.d_year
WHERE c.c_salutation = 'Dr.'
  AND c.c_birth_month = 7
  AND d.d_current_year = 'Y'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    c.c_salutation,
    c.c_birth_month,
    d_agg.d_quarter_name,
    d_agg.num_dates,
    d_agg.max_date
ORDER BY distinct_customers DESC
LIMIT 100

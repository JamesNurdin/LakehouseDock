WITH sampled_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_preferred_cust_flag,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        c_first_sales_date_sk,
        c_first_shipto_date_sk,
        c_last_review_date
    FROM customer
    TABLESAMPLE BERNOULLI (5)
    WHERE c_preferred_cust_flag = 'Y'
      AND c_birth_year BETWEEN 1960 AND 1985
      AND c_last_review_date >= 2452000
      AND c_first_sales_date_sk IS NOT NULL
)
SELECT
    sc.c_customer_id,
    sc.c_first_name,
    sc.c_last_name,
    d.d_date AS first_sales_date,
    d.d_year,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_date) AS sales_rank,
    CASE
        WHEN sc.c_birth_month IN (12, 1, 2) THEN 'Winter'
        WHEN sc.c_birth_month IN (3, 4, 5) THEN 'Spring'
        WHEN sc.c_birth_month IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS birth_season,
    (
        SELECT MAX(d2.d_year)
        FROM date_dim d2
        WHERE d2.d_date_sk = sc.c_first_shipto_date_sk
    ) AS max_shipto_year
FROM sampled_customers sc
JOIN date_dim d
  ON sc.c_first_sales_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2022-12-31'
  AND d.d_qoy = 1
  AND d.d_current_quarter = 'Y'
  AND d.d_last_dom > 2415000
  AND EXISTS (
        SELECT 1
        FROM date_dim d3
        WHERE d3.d_date_sk = sc.c_first_shipto_date_sk
          AND d3.d_qoy = 2
      )
ORDER BY d.d_year DESC, sales_rank
LIMIT 100

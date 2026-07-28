WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        c.c_login,
        c.c_first_shipto_date_sk,
        c.c_first_sales_date_sk,
        c.c_last_review_date
    FROM customer c
    WHERE c.c_birth_day BETWEEN 5 AND 20
      AND c.c_birth_month IN (1, 5, 12)
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_login IS NOT NULL
)
SELECT
    d_shipto.d_year AS shipto_year,
    d_sales.d_quarter_name AS sales_quarter,
    COUNT(DISTINCT fc.c_customer_sk) AS num_customers,
    AVG(fc.c_birth_year) AS avg_birth_year,
    MIN(d_review.d_date) AS earliest_review_date,
    MAX(d_review.d_date) AS latest_review_date,
    ROW_NUMBER() OVER (PARTITION BY d_shipto.d_year ORDER BY COUNT(DISTINCT fc.c_customer_sk) DESC) AS rn
FROM filtered_customers fc
JOIN date_dim d_shipto
    ON fc.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_sales
    ON fc.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON fc.c_last_review_date = d_review.d_date_sk
WHERE d_shipto.d_year BETWEEN 1995 AND 2000
  AND d_sales.d_quarter_name = '1901Q4'
  AND d_review.d_holiday = 'N'
  AND EXISTS (
        SELECT 1
        FROM date_dim d2
        WHERE d2.d_date_sk = fc.c_first_shipto_date_sk
          AND d2.d_dom = 15
    )
GROUP BY
    d_shipto.d_year,
    d_sales.d_quarter_name
HAVING COUNT(DISTINCT fc.c_customer_sk) > 10
ORDER BY num_customers DESC, shipto_year
LIMIT 100

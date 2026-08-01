WITH
    sampled_customer AS (
        SELECT
            c_customer_id,
            c_first_name,
            c_last_name,
            c_first_shipto_date_sk,
            c_first_sales_date_sk,
            c_last_review_date,
            c_salutation,
            c_preferred_cust_flag,
            c_birth_year,
            c_birth_month,
            c_current_hdemo_sk
        FROM tpcds.customer
        TABLESAMPLE BERNOULLI (10)
        WHERE c_salutation IN ('Mr.', 'Mrs.', 'Ms.', 'Dr.')
          AND c_preferred_cust_flag = 'Y'
          AND c_birth_year BETWEEN 1950 AND 1990
          AND c_current_hdemo_sk IS NOT NULL
    ),
    date_agg AS (
        SELECT
            d_date_sk,
            d_quarter_seq,
            d_year,
            COUNT(*) AS days_in_quarter
        FROM tpcds.date_dim
        WHERE d_current_quarter = 'Y'
          AND d_weekend = 'N'
          AND d_holiday = 'N'
          AND d_quarter_seq IN (4, 5, 20)
        GROUP BY d_date_sk, d_quarter_seq, d_year
    ),
    intersect_ids AS (
        SELECT c_customer_id
        FROM tpcds.customer
        WHERE c_birth_month = 1
        INTERSECT
        SELECT c_customer_id
        FROM tpcds.customer
        WHERE c_birth_month = 12
    )
SELECT
    sc.c_customer_id,
    sc.c_first_name,
    sc.c_last_name,
    da.d_year,
    da.days_in_quarter,
    (
        SELECT COUNT(*)
        FROM tpcds.date_dim dd2
        WHERE dd2.d_year = da.d_year
    ) AS total_days_in_year,
    CASE
        WHEN sc.c_customer_id IN (SELECT c_customer_id FROM intersect_ids) THEN 'BothJanDec'
        ELSE 'Other'
    END AS birth_month_category
FROM sampled_customer sc
JOIN date_agg da
    ON sc.c_first_shipto_date_sk = da.d_date_sk
WHERE da.d_quarter_seq >= 4
  AND sc.c_last_review_date IS NOT NULL
  AND EXISTS (
        SELECT 1
        FROM tpcds.date_dim d2
        WHERE d2.d_date_sk = sc.c_first_sales_date_sk
          AND d2.d_month_seq = da.d_quarter_seq
    )
ORDER BY da.d_year DESC, sc.c_customer_id
LIMIT 100

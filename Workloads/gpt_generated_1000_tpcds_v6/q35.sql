WITH customer_sales AS (
    SELECT
        ss.ss_customer_sk,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        MIN(d.d_date) AS first_sale_date,
        MAX(d.d_date) AS last_sale_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ss.ss_quantity > 0
    GROUP BY ss.ss_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    cd.cd_gender,
    hd.hd_income_band_sk,
    cs.sales_cnt,
    cs.total_sales,
    CASE
        WHEN regexp_like(c.c_email_address, '^.*@gmail\\.com$') THEN 'Gmail'
        WHEN regexp_like(c.c_email_address, '^.*@yahoo\\.com$') THEN 'Yahoo'
        ELSE 'Other'
    END AS email_domain_category,
    (SELECT AVG(cs2.total_sales) FROM customer_sales cs2) AS avg_total_sales_all,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = c.c_customer_sk AND ss2.ss_ext_sales_price > 1000) AS high_value_txn_cnt
FROM customer c
JOIN customer_sales cs ON c.c_customer_sk = cs.ss_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE regexp_like(c.c_login, '^user_[0-9]{3}$')
  AND c.c_email_address LIKE '%@%'
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss_h
        JOIN date_dim d_h ON ss_h.ss_sold_date_sk = d_h.d_date_sk
        WHERE ss_h.ss_customer_sk = c.c_customer_sk
          AND d_h.d_holiday = 'Y'
    )
UNION ALL
SELECT
    c2.c_customer_id,
    c2.c_first_name || ' ' || c2.c_last_name AS full_name,
    cd2.cd_gender,
    hd2.hd_income_band_sk,
    cs2.sales_cnt,
    cs2.total_sales,
    CASE
        WHEN regexp_like(c2.c_email_address, '^.*@example\\.com$') THEN 'ExampleCorp'
        ELSE 'Other'
    END AS email_domain_category,
    (SELECT AVG(cs3.total_sales) FROM customer_sales cs3) AS avg_total_sales_all,
    (SELECT COUNT(*) FROM store_sales ss3 WHERE ss3.ss_customer_sk = c2.c_customer_sk AND ss3.ss_ext_sales_price > 1000) AS high_value_txn_cnt
FROM customer c2
JOIN customer_sales cs2 ON c2.c_customer_sk = cs2.ss_customer_sk
JOIN customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
JOIN household_demographics hd2 ON c2.c_current_hdemo_sk = hd2.hd_demo_sk
WHERE c2.c_email_address LIKE '%@example.com'
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss_h2
        JOIN date_dim d_h2 ON ss_h2.ss_sold_date_sk = d_h2.d_date_sk
        WHERE ss_h2.ss_customer_sk = c2.c_customer_sk
          AND d_h2.d_holiday = 'Y'
    )
LIMIT 100

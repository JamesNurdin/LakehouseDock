WITH sales_per_customer AS (
    SELECT
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_count,
        AVG(ss_net_paid_inc_tax) AS avg_net_paid_inc_tax
    FROM store_sales
    WHERE ss_ext_discount_amt > 0
      AND ss_ext_sales_price BETWEEN 1000 AND 10000
      AND ss_quantity >= 1
    GROUP BY ss_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    cd.cd_credit_rating,
    cd.cd_dep_college_count,
    s.total_sales,
    s.total_discount,
    s.sales_count,
    s.avg_net_paid_inc_tax
FROM sales_per_customer s
JOIN customer c
    ON s.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE c.c_birth_country IN ('IRELAND', 'KOREA', 'UNITED ARAB EMIRATES')
  AND c.c_salutation = 'Ms.'
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_college_count >= 2
  AND cd.cd_purchase_estimate BETWEEN 5000 AND 9000
  AND s.total_sales > 5000
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_ext_discount_amt > 100
        LIMIT 1
    )
ORDER BY s.total_sales DESC, c.c_customer_id
LIMIT 100

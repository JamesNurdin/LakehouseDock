WITH recent_sales AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_paid,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2452600 AND 2452700
    GROUP BY ss_customer_sk
),
avg_total AS (
    SELECT AVG(total_paid) AS avg_paid FROM recent_sales
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    rs.total_paid,
    rs.sales_cnt,
    CASE
        WHEN rs.total_paid > (SELECT avg_paid FROM avg_total) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS spend_category
FROM recent_sales rs
JOIN customer c ON rs.ss_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'BURKINA FASO'
  AND EXISTS (
        SELECT 1 FROM store_sales s
        WHERE s.ss_customer_sk = c.c_customer_sk
          AND s.ss_ext_tax > 0
    )
UNION ALL
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    rs.total_paid,
    rs.sales_cnt,
    CASE
        WHEN rs.total_paid > (SELECT avg_paid FROM avg_total) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS spend_category
FROM recent_sales rs
JOIN customer c ON rs.ss_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'CAYMAN ISLANDS'
  AND NOT EXISTS (
        SELECT 1 FROM store_sales s
        WHERE s.ss_customer_sk = c.c_customer_sk
          AND s.ss_ext_tax > 0
    )
ORDER BY spend_category DESC, total_paid DESC

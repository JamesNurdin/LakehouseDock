WITH overall_avg AS (
    SELECT avg(ss_net_paid) AS avg_sales
    FROM store_sales ss
)
SELECT
    s.s_store_id,
    s.s_store_name,
    2022 AS sales_year,
    SUM(ss.ss_net_paid) AS total_sales,
    (SELECT avg_sales FROM overall_avg) AS overall_avg_sales
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 2022
  AND s.s_gmt_offset = -5.00
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_net_profit > 1000
      )
GROUP BY s.s_store_id, s.s_store_name
UNION ALL
SELECT
    s.s_store_id,
    s.s_store_name,
    2023 AS sales_year,
    SUM(ss.ss_net_paid) AS total_sales,
    (SELECT avg_sales FROM overall_avg) AS overall_avg_sales
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE d.d_year = 2023
  AND c.c_birth_month = 5
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_net_profit > 1000
      )
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_sales DESC
LIMIT 100

WITH sales_agg AS (
   SELECT
      d.d_year AS year,
      COUNT(*) AS cust_cnt,
      SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cnt,
      AVG(c.c_birth_year) AS avg_birth_year
   FROM customer c
   JOIN date_dim d
     ON c.c_first_sales_date_sk = d.d_date_sk
   WHERE d.d_year IN (1910, 1913, 1914)
     AND d.d_month_seq >= 240
     AND d.d_current_year = 'Y'
     AND c.c_birth_year BETWEEN 1960 AND 1990
   GROUP BY d.d_year
),
shipto_agg AS (
   SELECT
      d.d_year AS year,
      COUNT(*) AS cust_cnt,
      SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cnt,
      AVG(c.c_birth_year) AS avg_birth_year
   FROM customer c
   JOIN date_dim d
     ON c.c_first_shipto_date_sk = d.d_date_sk
   WHERE d.d_year IN (1910, 1913, 1914)
     AND d.d_month_seq >= 240
     AND d.d_current_year = 'Y'
     AND c.c_birth_year BETWEEN 1960 AND 1990
   GROUP BY d.d_year
),
combined AS (
   SELECT year, cust_cnt, pref_cnt, avg_birth_year, 'sales'   AS metric_type FROM sales_agg
   UNION ALL
   SELECT year, cust_cnt, pref_cnt, avg_birth_year, 'shipto' AS metric_type FROM shipto_agg
)
SELECT
   metric_type,
   AVG(cust_cnt)                           AS avg_cust_cnt,
   SUM(pref_cnt)                           AS total_pref_cnt,
   AVG(avg_birth_year)                     AS avg_of_avg_birth_year,
   CASE
      WHEN AVG(cust_cnt) > 1000 THEN 'high'
      WHEN AVG(cust_cnt) > 500  THEN 'medium'
      ELSE 'low'
   END                                     AS volume_category
FROM combined
WHERE year >= 1910
GROUP BY metric_type
HAVING SUM(pref_cnt) > 10
ORDER BY avg_cust_cnt DESC
LIMIT 100

/*
Goal: Summarize active customers per web site and calendar year, then rank web sites by a weighted metric that combines customer count and average birth year. The query applies multiple filters on dates, web site attributes, and customer flags, includes an EXISTS subquery, performs a two‑level aggregation, orders the final result, and limits it to the top 100 rows.
*/
WITH site_year_stats AS (
    SELECT
        ws.web_site_id,
        dd.d_year,
        COUNT(DISTINCT c.c_customer_sk) AS cust_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        COUNT(DISTINCT c.c_customer_sk) * AVG(c.c_birth_year) AS weighted_metric
    FROM web_site ws
    JOIN date_dim dd
        ON ws.web_open_date_sk = dd.d_date_sk
    JOIN customer c
        ON c.c_first_shipto_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2000 AND 2005                              -- predicate 1
      AND ws.web_street_type = 'Avenue'                                 -- predicate 2
      AND ws.web_company_id IN (1, 3, 5)                                 -- predicate 3
      AND c.c_preferred_cust_flag = 'Y'                                 -- predicate 4
      AND c.c_birth_country = 'United States'                           -- predicate 5
      AND EXISTS (                                                       -- subquery predicate
            SELECT 1
            FROM date_dim d2
            WHERE d2.d_date_sk = ws.web_close_date_sk
              AND d2.d_week_seq = 10
        )
    GROUP BY ws.web_site_id, dd.d_year
)
SELECT
    web_site_id,
    SUM(cust_cnt) AS total_customers,
    AVG(weighted_metric) AS avg_weighted_metric
FROM site_year_stats
GROUP BY web_site_id
HAVING SUM(cust_cnt) > 20                     -- filter on the second‑level aggregate
ORDER BY avg_weighted_metric DESC
LIMIT 100

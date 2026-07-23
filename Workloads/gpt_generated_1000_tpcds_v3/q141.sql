WITH ship_counts AS (
    SELECT d.d_year AS event_year,
           'first_ship' AS event_type,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND d.d_current_day = 'N'
    GROUP BY d.d_year
),
sales_counts AS (
    SELECT d.d_year AS event_year,
           'first_sales' AS event_type,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND d.d_current_day = 'N'
    GROUP BY d.d_year
)
SELECT ship_counts.event_year,
       ship_counts.event_type,
       ship_counts.customer_count
FROM ship_counts
UNION ALL
SELECT sales_counts.event_year,
       sales_counts.event_type,
       sales_counts.customer_count
FROM sales_counts
ORDER BY event_year, event_type
LIMIT 100

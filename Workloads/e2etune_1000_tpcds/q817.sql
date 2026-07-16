WITH country_metrics AS (
    SELECT
        c.c_birth_country AS country,
        COUNT(DISTINCT c.c_customer_id) AS num_customers,
        AVG(s.s_floor_space) AS avg_store_floor_space,
        AVG(ws.web_tax_percentage) AS avg_web_tax_percentage,
        COUNT(DISTINCT s.s_store_id) AS num_stores,
        COUNT(DISTINCT ws.web_site_id) AS num_websites,
        MAX(c.c_birth_year) AS latest_birth_year,
        MIN(c.c_birth_year) AS earliest_birth_year
    FROM customer c
    JOIN store s
        ON c.c_birth_country = s.s_country
    JOIN web_site ws
        ON s.s_country = ws.web_country
    WHERE c.c_birth_month IN (4, 7, 10)
      AND s.s_floor_space >= 5000
      AND ws.web_tax_percentage > 0.05
    GROUP BY c.c_birth_country
    HAVING COUNT(DISTINCT c.c_customer_id) >= 5
)
SELECT
    country,
    num_customers,
    avg_store_floor_space,
    avg_web_tax_percentage,
    num_stores,
    num_websites,
    latest_birth_year,
    earliest_birth_year,
    RANK() OVER (ORDER BY num_customers DESC) AS country_rank
FROM country_metrics
ORDER BY country_rank
LIMIT 10

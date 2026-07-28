WITH inv_agg AS (
    SELECT d.d_year AS period_year,
           'Inventory' AS category,
           SUM(i.inv_quantity_on_hand) AS metric
    FROM tpcds.inventory i
    JOIN tpcds.date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
),
web_agg AS (
    SELECT d.d_year AS period_year,
           'Website Openings' AS category,
           COUNT(DISTINCT w.web_site_sk) AS metric
    FROM tpcds.web_site w
    JOIN tpcds.date_dim d ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
),
combined AS (
    SELECT * FROM inv_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT period_year,
       category,
       metric,
       CASE WHEN metric > 1000 THEN 'High' ELSE 'Low' END AS level
FROM combined
ORDER BY period_year, category
LIMIT 100

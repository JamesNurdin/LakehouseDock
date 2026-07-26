WITH ship_stats AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_day_name,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        SUM(cs.cs_ext_tax) AS total_tax,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_ship_cost) DESC) AS ship_cost_rank
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date, d.d_day_name
)
SELECT
    ss.d_date,
    ss.d_day_name,
    ss.total_ship_cost,
    ss.total_tax,
    ss.avg_discount,
    ss.distinct_items,
    ss.ship_cost_rank,
    CASE
        WHEN ss.total_ship_cost > 200000 THEN 'Very High'
        WHEN ss.total_ship_cost > 100000 THEN 'High'
        WHEN ss.total_ship_cost > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS ship_cost_category,
    ws.web_name,
    wp.wp_url
FROM ship_stats ss
LEFT JOIN web_site ws ON ws.web_close_date_sk = ss.d_date_sk
LEFT JOIN web_page wp ON wp.wp_access_date_sk = ss.d_date_sk
WHERE ss.ship_cost_rank <= 20
ORDER BY ss.ship_cost_rank

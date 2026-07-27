WITH yearly_sales AS (
    SELECT
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1997 AND 1999
    GROUP BY d.d_year
)
SELECT
    y.year,
    y.total_net_profit AS metric,
    'store_sales' AS source
FROM yearly_sales y
WHERE y.total_net_profit > (
    SELECT AVG(ss_inner.ss_net_paid)
    FROM store_sales ss_inner
)
UNION ALL
SELECT
    d.d_year AS year,
    COUNT(ws.web_site_sk) AS metric,
    'web_site' AS source
FROM web_site ws
JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1997 AND 1999
  AND EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_access_date_sk = d.d_date_sk
      AND wp.wp_type = 'article'
)
GROUP BY d.d_year
LIMIT 100

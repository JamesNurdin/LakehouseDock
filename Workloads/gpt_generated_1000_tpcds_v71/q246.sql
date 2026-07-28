WITH cat_sales AS (
    SELECT d.d_year AS year,
           SUM(cs.cs_net_paid) AS net_paid,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year
),
web_sales AS (
    SELECT d.d_year AS year,
           SUM(ws.ws_net_paid) AS net_paid,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year
),
combined AS (
    SELECT channel, year, net_paid FROM cat_sales
    UNION ALL
    SELECT channel, year, net_paid FROM web_sales
)
SELECT
    CASE WHEN GROUPING(year) = 1 THEN 'All Years' ELSE CAST(year AS VARCHAR) END AS year,
    channel,
    SUM(net_paid) AS total_net_paid
FROM combined
GROUP BY GROUPING SETS (
    (channel, year),
    (channel),
    ()
)
ORDER BY channel, year
LIMIT 100

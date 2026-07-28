WITH catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        'catalog' AS source,
        SUM(cs.cs_net_paid) AS net_paid
    FROM catalog_sales AS cs
    JOIN time_dim AS td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cs.cs_sold_date_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        'web' AS source,
        SUM(ws.ws_net_paid) AS net_paid
    FROM web_sales AS ws
    JOIN time_dim AS td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ws.ws_sold_date_sk
),
combined AS (
    SELECT date_sk, source, net_paid FROM catalog_sales_agg
    UNION ALL
    SELECT date_sk, source, net_paid FROM web_sales_agg
)
SELECT
    c.date_sk,
    c.source,
    c.net_paid,
    ROW_NUMBER() OVER (PARTITION BY c.source ORDER BY c.net_paid DESC) AS rn,
    SUM(c.net_paid) OVER (PARTITION BY c.source ORDER BY c.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid
FROM combined AS c
ORDER BY c.source, c.net_paid DESC
LIMIT 100

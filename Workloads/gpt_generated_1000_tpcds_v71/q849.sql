WITH catalog_agg AS (
    SELECT
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        'Catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
    GROUP BY d.d_year, d.d_month_seq
),
web_agg AS (
    SELECT
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        'Web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN SUM(ws.ws_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
    GROUP BY d.d_year, d.d_month_seq
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
),
distinct_combined AS (
    SELECT DISTINCT
        sales_year,
        sales_month,
        channel,
        total_net_paid,
        sales_level
    FROM combined
)
SELECT
    dc.sales_year,
    dc.sales_month,
    dc.channel,
    dc.total_net_paid,
    dc.sales_level,
    ROW_NUMBER() OVER (PARTITION BY dc.sales_year ORDER BY dc.total_net_paid DESC) AS sales_rank
FROM distinct_combined dc
ORDER BY dc.sales_year, dc.sales_month, dc.channel

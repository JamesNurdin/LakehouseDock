WITH catalog_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        'catalog' AS source,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_item_sk
),
web_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        'web' AS source,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_item_sk
)
SELECT DISTINCT
    combined.item_sk,
    combined.source,
    combined.total_sales,
    combined.sales_rank
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) AS combined
ORDER BY combined.sales_rank
LIMIT 100

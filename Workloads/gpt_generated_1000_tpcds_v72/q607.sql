WITH store_agg AS (
   SELECT
        i.i_item_id AS item_id,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        (
            SELECT AVG(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
            WHERE cs.cs_item_sk = ss.ss_item_sk
              AND d2.d_year = 2002
        ) AS avg_catalog_sales
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2002
   GROUP BY i.i_item_id, ss.ss_item_sk
),
web_agg AS (
   SELECT
        i.i_item_id AS item_id,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        (
            SELECT AVG(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
            WHERE cs.cs_item_sk = ws.ws_item_sk
              AND d2.d_year = 2002
        ) AS avg_catalog_sales
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2002
   GROUP BY i.i_item_id, ws.ws_item_sk
)
SELECT DISTINCT
    combined.item_id,
    combined.channel,
    combined.total_sales,
    combined.avg_catalog_sales
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) AS combined
WHERE combined.total_sales > 1000
ORDER BY combined.total_sales DESC, combined.item_id
LIMIT 100

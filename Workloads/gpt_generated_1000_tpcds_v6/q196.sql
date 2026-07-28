WITH catalog_raw AS (
    SELECT
        i.i_category AS category,
        cs.cs_sold_date_sk AS date_key,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451150
    GROUP BY GROUPING SETS (
        (i.i_category, cs.cs_sold_date_sk),
        (i.i_category),
        ()
    )
),
catalog_agg AS (
    SELECT
        category,
        date_key,
        total_sales,
        CASE WHEN total_sales > 100000 THEN 'High' ELSE 'Low' END AS sales_level,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_sales DESC) AS sales_rank
    FROM catalog_raw
),
store_raw AS (
    SELECT
        i.i_category AS category,
        ss.ss_sold_date_sk AS date_key,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451150
    GROUP BY GROUPING SETS (
        (i.i_category, ss.ss_sold_date_sk),
        (i.i_category),
        ()
    )
),
store_agg AS (
    SELECT
        category,
        date_key,
        total_sales,
        CASE WHEN total_sales > 50000 THEN 'High' ELSE 'Low' END AS sales_level,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_sales DESC) AS sales_rank
    FROM store_raw
)
SELECT *
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
) combined
ORDER BY category,
         date_key NULLS LAST,
         total_sales DESC
LIMIT 100

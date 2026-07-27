/*
Goal: Identify the top‑selling "electronic" items and indicate whether each item has any associated catalog return that was linked to a catalog page whose description mentions "clearance". The query uses a CTE for sales aggregation, string functions (REGEXP_LIKE, SUBSTRING, CONCAT), a correlated EXISTS subquery, joins per the allowed rules, and orders the result by profit.
*/
WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)electronic')
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_color
)
SELECT
    isales.i_item_id,
    SUBSTRING(isales.i_item_desc FROM 1 FOR 30) AS short_desc,
    CONCAT(isales.i_brand, ' ', isales.i_color) AS brand_color,
    isales.total_sales,
    isales.total_profit,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM catalog_returns cr
            JOIN catalog_page cp
                ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
            WHERE cr.cr_item_sk = isales.i_item_sk
              AND regexp_like(cp.cp_description, '(?i)clearance')
        ) THEN 'Has Clearance Return'
        ELSE 'No Clearance Return'
    END AS clearance_return_flag
FROM item_sales isales
WHERE isales.total_sales > 10000
ORDER BY isales.total_profit DESC
LIMIT 50

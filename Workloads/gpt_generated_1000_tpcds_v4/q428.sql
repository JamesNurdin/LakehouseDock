-- Goal: Identify the top‑selling items by combined catalog and web revenue, classify their revenue level, rank them, and keep only those whose total revenue exceeds the overall average.
WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS catalog_rev,
        SUM(ws.ws_ext_sales_price) AS web_rev
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    WHERE cp.cp_end_date_sk BETWEEN 2450870 AND 2451200
      AND i.i_category_id IN (4, 9)
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND cs.cs_quantity > 5
      AND ws.ws_list_price > 100
    GROUP BY i.i_item_sk, i.i_product_name
    HAVING SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) > 1000
),
avg_rev AS (
    SELECT AVG(total_rev) AS avg_rev FROM (
        SELECT
            SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_rev
        FROM catalog_sales cs
        JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
        JOIN web_sales ws ON ws.ws_item_sk = i2.i_item_sk
        GROUP BY i2.i_item_sk
    ) t
),
ranked AS (
    SELECT
        i_item_sk,
        i_product_name,
        catalog_rev,
        web_rev,
        (catalog_rev + web_rev) AS total_rev,
        CASE
            WHEN (catalog_rev + web_rev) >= 5000 THEN 'High'
            WHEN (catalog_rev + web_rev) >= 2000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_bucket,
        ROW_NUMBER() OVER (ORDER BY (catalog_rev + web_rev) DESC) AS revenue_rank
    FROM item_sales
)
SELECT
    r.i_item_sk,
    r.i_product_name,
    r.catalog_rev,
    r.web_rev,
    r.total_rev,
    r.revenue_bucket,
    r.revenue_rank,
    ar.avg_rev
FROM ranked r
CROSS JOIN avg_rev ar
WHERE r.total_rev > ar.avg_rev
ORDER BY r.total_rev DESC
LIMIT 20

/*
Goal: Compare daily net paid revenue from catalog and web sales, classify the revenue level, compute cumulative revenue per channel, rank days by revenue, and return the top 100 rows.
*/
WITH catalog_agg AS (
    SELECT
        cs.cs_sold_date_sk AS sales_date_sk,
        'catalog' AS source,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'high' ELSE 'medium' END AS sales_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_department = 'Electronics'
      AND p.p_discount_active = 'Y'
    GROUP BY cs.cs_sold_date_sk
),
web_agg AS (
    SELECT
        ws.ws_sold_date_sk AS sales_date_sk,
        'web' AS source,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN SUM(ws.ws_net_paid) > 80000 THEN 'high' ELSE 'medium' END AS sales_category
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE wp.wp_type = 'Content'
      AND p.p_discount_active = 'Y'
    GROUP BY ws.ws_sold_date_sk
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT DISTINCT
    source,
    sales_date_sk,
    total_net_paid,
    sales_category,
    SUM(total_net_paid) OVER (
        PARTITION BY source
        ORDER BY sales_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid,
    ROW_NUMBER() OVER (
        PARTITION BY source
        ORDER BY total_net_paid DESC
    ) AS rank_per_source
FROM combined
ORDER BY source, total_net_paid DESC
LIMIT 100

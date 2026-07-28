WITH cs_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        CASE
            WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High'
            WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(i.i_product_name, '(?i)TV|Phone')
      AND cp.cp_description LIKE '%electronics%'
    GROUP BY i.i_item_sk, i.i_product_name
    HAVING SUM(cs.cs_ext_sales_price) > 0
),
ss_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High'
            WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_extract(i.i_product_name, '(TV|Phone)', 1) IS NOT NULL
      AND s.s_city LIKE 'San%'
    GROUP BY i.i_item_sk, i.i_product_name
    HAVING SUM(ss.ss_ext_sales_price) > 0
)
SELECT DISTINCT source,
       i_item_sk,
       i_product_name,
       total_sales,
       num_orders,
       sales_category,
       sales_rank
FROM (
    SELECT
        'catalog' AS source,
        i_item_sk,
        i_product_name,
        total_sales,
        num_orders,
        sales_category,
        sales_rank
    FROM cs_agg
    UNION ALL
    SELECT
        'store' AS source,
        i_item_sk,
        i_product_name,
        total_sales,
        num_tickets AS num_orders,
        sales_category,
        sales_rank
    FROM ss_agg
) combined
WHERE sales_rank = 1
ORDER BY total_sales DESC
LIMIT 100

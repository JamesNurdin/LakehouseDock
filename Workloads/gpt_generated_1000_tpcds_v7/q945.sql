WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_description,
        d_start.d_year,
        d_start.d_month_seq
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    WHERE regexp_like(cp.cp_description, '(?i)goods')
)
SELECT
    cp.cp_catalog_page_id,
    CONCAT(cp.cp_catalog_page_id, '-', i.i_item_id) AS page_item_key,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cs.cs_quantity) AS avg_quantity
FROM filtered_pages cp
JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE i.i_item_desc LIKE '%blue%'
  AND regexp_extract(i.i_item_desc, '(?i)large\s+blue', 0) IS NOT NULL
GROUP BY
    cp.cp_catalog_page_id,
    CONCAT(cp.cp_catalog_page_id, '-', i.i_item_id),
    d.d_year,
    d.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100

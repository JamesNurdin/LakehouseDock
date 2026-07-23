WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        CONCAT(cp.cp_department, '-', cp.cp_type) AS page_category,
        regexp_extract(cp.cp_catalog_page_id, '([A-Z]+[0-9]+)', 1) AS page_id_alpha_num,
        SUBSTRING(cp.cp_description FROM 1 FOR 10) AS short_desc
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '(?i)\\b(sale|discount)\\b')
      AND cp.cp_department LIKE 'Electronics%'
), sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
    FROM catalog_sales cs
    GROUP BY cs.cs_catalog_page_sk, cs.cs_sold_date_sk
), inventory_agg AS (
    SELECT
        i.inv_date_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    GROUP BY i.inv_date_sk
)
SELECT
    fp.page_category,
    d.d_year,
    fp.page_id_alpha_num,
    fp.short_desc,
    s.total_net_paid,
    s.total_net_profit,
    s.distinct_items_sold,
    i.total_inventory_qty
FROM filtered_pages fp
JOIN sales_agg s
    ON fp.cp_catalog_page_sk = s.cs_catalog_page_sk
JOIN date_dim d
    ON s.cs_sold_date_sk = d.d_date_sk
LEFT JOIN inventory_agg i
    ON d.d_date_sk = i.inv_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND fp.page_category LIKE '%-%'
ORDER BY s.total_net_paid DESC
LIMIT 100

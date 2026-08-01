WITH sales_items AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        regexp_extract(i.i_product_name, '(\\d+)', 1) AS extracted_number,
        cp.cp_description
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2002
      AND regexp_like(i.i_product_name, '\\d{2,}')
      AND i.i_category LIKE 'A%'
      AND cp.cp_description LIKE '%new%'
)
SELECT
    i_category,
    extracted_number,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    CASE
        WHEN SUM(net_profit) > 0 THEN 'PROFITABLE'
        WHEN SUM(net_profit) = 0 THEN 'NEUTRAL'
        ELSE 'LOSS'
    END AS profit_bucket,
    CONCAT(i_category, '-', COALESCE(extracted_number, '0')) AS category_number_key
FROM sales_items
GROUP BY i_category, extracted_number
ORDER BY total_net_profit DESC
LIMIT 100

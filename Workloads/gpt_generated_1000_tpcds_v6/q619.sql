WITH avg_profit_cte AS (
    SELECT avg(cs_net_profit) AS avg_profit
    FROM catalog_sales
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    COUNT(cs.cs_order_number) AS orders,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE 
        WHEN SUM(cs.cs_net_profit) > (SELECT avg_profit FROM avg_profit_cte) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg,
    regexp_extract(cp.cp_description, '(Legal|Classic|Schools)', 1) AS key_term,
    CASE 
        WHEN regexp_like(cp.cp_description, '.*Legal.*') THEN 'Legal'
        WHEN regexp_like(cp.cp_description, '.*Classic.*') THEN 'Classic'
        ELSE 'Other'
    END AS description_category,
    CONCAT(i.i_brand, ' ', i.i_product_name) AS full_product_name,
    SUBSTRING(i.i_item_desc FROM 1 FOR 30) AS short_item_desc
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE
    d.d_year = 2001
    AND cp.cp_description LIKE '%building%'
    AND regexp_like(cc.cc_zip, '^85[0-9]{3}$')
    AND EXISTS (
        SELECT 1
        FROM web_site ws
        JOIN date_dim dw ON ws.web_open_date_sk = dw.d_date_sk
        WHERE ws.web_state = 'CA' AND dw.d_year = 2001
    )
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_department,
    i.i_brand,
    i.i_product_name,
    i.i_item_desc,
    cp.cp_description
ORDER BY total_profit DESC
LIMIT 100

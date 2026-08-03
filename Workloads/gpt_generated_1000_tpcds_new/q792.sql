WITH sales_pre AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        i.i_product_name,
        i.i_category,
        t.t_am_pm,
        t.t_hour
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
      AND i.i_category LIKE 'Electronics%'
)
SELECT
    cc.cc_name,
    sp.i_category,
    l.short_name,
    SUM(sp.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT sp.cs_order_number) AS order_cnt,
    CASE WHEN SUM(sp.cs_quantity) > 1000 THEN 'High Volume' ELSE 'Regular Volume' END AS volume_flag,
    REGEXP_EXTRACT(sp.i_product_name, '(\\d{4})', 1) AS extracted_code
FROM sales_pre sp
JOIN call_center cc ON sp.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN LATERAL (
    SELECT substr(sp.i_product_name, 1, 12) AS short_name
) AS l ON TRUE
WHERE sp.cs_order_number NOT IN (
    SELECT cr.cr_order_number FROM catalog_returns cr WHERE cr.cr_return_quantity > 0
)
AND EXISTS (
    SELECT 1 FROM reason r WHERE r.r_reason_desc LIKE '%defect%'
)
GROUP BY cc.cc_name, sp.i_category, l.short_name, REGEXP_EXTRACT(sp.i_product_name, '(\\d{4})', 1)
ORDER BY total_sales DESC
LIMIT 100

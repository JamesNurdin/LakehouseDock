WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_description,
        cp.cp_type,
        SUBSTRING(cp.cp_description, 1, 30) AS short_desc,
        regexp_extract(cp.cp_description, '(?i)(goods|sales)', 1) AS extracted_term,
        cp.cp_description || ' - ' || cp.cp_type AS full_desc_type
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '(?i)goods')
      AND cp.cp_type LIKE 'C%'
)
SELECT
    cc.cc_name || ' - ' || fp.cp_catalog_page_id AS call_center_page,
    fp.cp_department,
    fp.cp_catalog_number,
    fp.cp_catalog_page_number,
    fp.short_desc,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(fp.cp_description) AS example_description
FROM filtered_pages fp
JOIN catalog_sales cs ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_rec_start_date >= DATE '1998-01-01'
  AND cc.cc_rec_start_date <= DATE '1998-12-31'
GROUP BY
    cc.cc_name || ' - ' || fp.cp_catalog_page_id,
    fp.cp_department,
    fp.cp_catalog_number,
    fp.cp_catalog_page_number,
    fp.short_desc
ORDER BY total_sales DESC
LIMIT 100

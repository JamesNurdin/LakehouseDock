WITH page_returns AS (
  SELECT
    cp.cp_catalog_page_sk AS cp_sk,
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    w.w_warehouse_name AS warehouse_name,
    p.p_promo_name AS promo_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    REGEXP_EXTRACT(cp.cp_catalog_page_id, 'A{3}(.*)A{3}', 1) AS extracted_id_part
  FROM catalog_returns cr
  JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE REGEXP_LIKE(cp.cp_type, 'monthly|quarterly')
    AND cp.cp_description LIKE '%special%'
    AND p.p_promo_name LIKE '%Discount%'
  GROUP BY cp.cp_catalog_page_sk,
           cp.cp_catalog_page_id,
           cp.cp_department,
           cp.cp_type,
           w.w_warehouse_name,
           p.p_promo_name,
           REGEXP_EXTRACT(cp.cp_catalog_page_id, 'A{3}(.*)A{3}', 1)
)
SELECT *
FROM (
  SELECT
    cp_sk,
    cp_catalog_page_id,
    CONCAT(cp_department, '-', cp_type) AS dept_type,
    warehouse_name,
    promo_name,
    total_return_amount,
    return_cnt,
    extracted_id_part,
    ROW_NUMBER() OVER (PARTITION BY warehouse_name ORDER BY total_return_amount DESC) AS rn
  FROM page_returns
) t
WHERE rn <= 10
ORDER BY total_return_amount DESC
LIMIT 100

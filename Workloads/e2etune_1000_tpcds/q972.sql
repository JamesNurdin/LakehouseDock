SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_start_date_sk,
    i.i_brand,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_page_cnt,
    COUNT(DISTINCT i.i_item_sk) AS item_cnt,
    SUM(wp.wp_image_count) AS total_image_count,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(wp.wp_link_count) AS total_link_count,
    RANK() OVER (ORDER BY SUM(wp.wp_link_count) DESC) AS link_rank
FROM catalog_page cp
JOIN web_page wp
    ON cp.cp_start_date_sk = wp.wp_creation_date_sk
JOIN item i
    ON cp.cp_catalog_page_id = i.i_item_id
WHERE cp.cp_type = 'monthly'
  AND cp.cp_department = 'DEPARTMENT'
  AND cp.cp_start_date_sk IN (2450815, 2450997, 2450906)
  AND i.i_brand IS NOT NULL
GROUP BY cp.cp_department, cp.cp_type, cp.cp_start_date_sk, i.i_brand
HAVING COUNT(DISTINCT i.i_item_sk) > 5
ORDER BY total_link_count DESC
LIMIT 15

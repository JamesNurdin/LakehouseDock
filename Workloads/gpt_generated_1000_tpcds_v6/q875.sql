/*
Goal: Analyze promotional spend and web page activity linked to catalog pages for the Electronics catalog in 2001, categorizing pages by size, producing departmental and page-type subtotals, and ranking pages by total promotion cost.
*/
WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        p.p_cost,
        wp.wp_web_page_id,
        wp.wp_type,
        c.c_customer_id,
        d.d_date,
        d.d_year
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN customer c ON c.c_first_shipto_date_sk = d.d_date_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_type = 'Catalog'
      AND p.p_discount_active = 'Y'
      AND d.d_year = 2001
      AND wp.wp_type = 'HomePage'
      AND c.c_preferred_cust_flag = 'Y'
),
agg AS (
    SELECT
        cp_department,
        wp_type,
        cp_catalog_page_number,
        CASE WHEN cp_catalog_page_number >= 15 THEN 'High Page' ELSE 'Standard Page' END AS page_category,
        COUNT(DISTINCT cp_catalog_page_id) AS catalog_pages,
        COUNT(DISTINCT wp_web_page_id) AS web_pages,
        SUM(p_cost) AS total_promo_cost
    FROM base
    GROUP BY ROLLUP (cp_department, wp_type, cp_catalog_page_number)
)
SELECT
    cp_department,
    wp_type,
    cp_catalog_page_number,
    page_category,
    catalog_pages,
    web_pages,
    total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_promo_cost DESC) AS dept_page_rank,
    RANK() OVER (ORDER BY total_promo_cost DESC) AS overall_rank
FROM agg
ORDER BY cp_department, wp_type, cp_catalog_page_number
LIMIT 100

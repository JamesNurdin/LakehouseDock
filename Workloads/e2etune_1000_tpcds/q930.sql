WITH base AS (
    SELECT
        cp.cp_department AS cp_department,
        hd.hd_vehicle_count AS hd_vehicle_count,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_pages,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(wp.wp_image_count) AS avg_image_count
    FROM catalog_page cp
    JOIN promotion p
        ON cp.cp_start_date_sk = p.p_start_date_sk
    JOIN web_page wp
        ON cp.cp_start_date_sk = wp.wp_creation_date_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = p.p_promo_sk
    WHERE cp.cp_end_date_sk BETWEEN 2450800 AND 2451100
      AND p.p_discount_active = 'Y'
      AND wp.wp_type = 'Content'
    GROUP BY cp.cp_department, hd.hd_vehicle_count
    HAVING SUM(p.p_cost) > 1000
)
SELECT
    cp_department,
    hd_vehicle_count,
    num_pages,
    total_promo_cost,
    avg_image_count,
    RANK() OVER (ORDER BY total_promo_cost DESC) AS promo_cost_rank
FROM base
ORDER BY total_promo_cost DESC
LIMIT 50

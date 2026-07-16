WITH inv_cp AS (
    SELECT i.inv_date_sk,
           i.inv_quantity_on_hand,
           cp.cp_department
    FROM inventory i
    JOIN catalog_page cp ON i.inv_date_sk = cp.cp_start_date_sk
    WHERE cp.cp_department = 'DEPARTMENT'
),
wp_cd AS (
    SELECT wp.wp_access_date_sk,
           wp.wp_web_page_id,
           cd.cd_gender,
           cd.cd_purchase_estimate
    FROM web_page wp
    JOIN customer_demographics cd ON wp.wp_customer_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate >= 500
)
SELECT
    dept,
    gender,
    total_quantity,
    avg_purchase_estimate,
    distinct_web_pages,
    RANK() OVER (PARTITION BY gender ORDER BY total_quantity DESC) AS dept_rank_by_quantity
FROM (
    SELECT
        icp.cp_department AS dept,
        wcd.cd_gender AS gender,
        SUM(icp.inv_quantity_on_hand) AS total_quantity,
        AVG(wcd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT wcd.wp_web_page_id) AS distinct_web_pages
    FROM inv_cp icp
    JOIN wp_cd wcd ON icp.inv_date_sk = wcd.wp_access_date_sk
    WHERE icp.inv_quantity_on_hand > 0
    GROUP BY icp.cp_department, wcd.cd_gender
    HAVING SUM(icp.inv_quantity_on_hand) > 100
) agg
ORDER BY total_quantity DESC
LIMIT 50

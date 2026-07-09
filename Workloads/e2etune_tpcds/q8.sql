SELECT
    gender,
    meal_time,
    page_views,
    avg_char_count,
    product_page_views,
    RANK() OVER (PARTITION BY meal_time ORDER BY page_views DESC) AS gender_rank
FROM (
    SELECT
        cd.cd_gender AS gender,
        td.t_meal_time AS meal_time,
        COUNT(*) AS page_views,
        AVG(wp.wp_char_count) AS avg_char_count,
        SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_views
    FROM web_page wp
    JOIN customer_demographics cd ON wp.wp_customer_sk = cd.cd_demo_sk
    JOIN time_dim td ON wp.wp_access_date_sk = td.t_time_sk
    WHERE cd.cd_purchase_estimate >= 1500
      AND wp.wp_type IN ('product', 'category')
      AND td.t_meal_time IS NOT NULL
    GROUP BY cd.cd_gender, td.t_meal_time
    HAVING COUNT(*) > 100
) sub
ORDER BY meal_time, gender_rank

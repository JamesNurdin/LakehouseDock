WITH hd_agg AS (
    SELECT
        hd_buy_potential,
        COUNT(*) AS num_households,
        SUM(hd_vehicle_count) AS total_vehicles,
        AVG(hd_dep_count) AS avg_dependents
    FROM household_demographics
    WHERE hd_income_band_sk BETWEEN 2 AND 6
      AND hd_vehicle_count > 0
    GROUP BY hd_buy_potential
    HAVING COUNT(*) >= 2
),
wp_agg AS (
    SELECT
        CASE
            WHEN wp_image_count <= 3 THEN '0-500'
            WHEN wp_image_count <= 5 THEN '501-1000'
            WHEN wp_image_count <= 7 THEN '1001-5000'
            ELSE '>10000'
        END AS buy_potential_bucket,
        COUNT(*) AS num_pages,
        SUM(wp_image_count) AS total_images,
        AVG(wp_char_count) AS avg_chars
    FROM web_page
    WHERE wp_type IS NOT NULL
    GROUP BY CASE
        WHEN wp_image_count <= 3 THEN '0-500'
        WHEN wp_image_count <= 5 THEN '501-1000'
        WHEN wp_image_count <= 7 THEN '1001-5000'
        ELSE '>10000'
    END
    HAVING COUNT(*) >= 1
)
SELECT
    hd.hd_buy_potential,
    hd.num_households,
    hd.total_vehicles,
    hd.avg_dependents,
    wp.num_pages,
    wp.total_images,
    wp.avg_chars,
    (hd.total_vehicles * 1.0 / NULLIF(wp.total_images, 0)) AS vehicles_per_image
FROM hd_agg hd
JOIN wp_agg wp
    ON hd.hd_buy_potential = wp.buy_potential_bucket
WHERE hd.total_vehicles > 5
ORDER BY vehicles_per_image DESC
LIMIT 100

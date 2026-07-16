WITH cp_agg AS (
    SELECT cp_type,
           COUNT(*) AS total_pages,
           AVG(cp_catalog_number) AS avg_catalog_number,
           MIN(cp_start_date_sk) AS min_start_date_sk,
           MAX(cp_end_date_sk) AS max_end_date_sk
    FROM catalog_page
    WHERE cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND cp_type IN ('monthly', 'quarterly')
    GROUP BY cp_type
),
cd_agg AS (
    SELECT AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           COUNT(*) AS total_customers,
           SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
           SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers
    FROM customer_demographics
    WHERE cd_credit_rating = 'A'
),
hd_agg AS (
    SELECT AVG(hd_vehicle_count) AS avg_vehicle_count,
           AVG(hd_dep_count) AS avg_dep_count,
           COUNT(*) AS total_households
    FROM household_demographics
    WHERE hd_buy_potential = 'HIGH'
),
sm_agg AS (
    SELECT sm_type,
           COUNT(*) AS total_ship_modes,
           COUNT(DISTINCT sm_carrier) AS distinct_carriers
    FROM ship_mode
    WHERE sm_contract = 'Y'
    GROUP BY sm_type
),
store_agg AS (
    SELECT s_state,
           AVG(s_floor_space) AS avg_floor_space,
           COUNT(*) AS total_stores
    FROM store
    WHERE s_market_desc = 'Online'
    GROUP BY s_state
),
wp_agg AS (
    SELECT wp_type,
           COUNT(*) AS total_web_pages,
           SUM(wp_link_count) AS total_links
    FROM web_page
    WHERE wp_creation_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY wp_type
)
SELECT
    cp.cp_type,
    cp.total_pages,
    cp.avg_catalog_number,
    RANK() OVER (ORDER BY cp.total_pages DESC) AS cp_type_rank,
    cd.avg_purchase_estimate,
    cd.total_customers,
    cd.male_customers,
    cd.female_customers,
    hd.avg_vehicle_count,
    hd.avg_dep_count,
    hd.total_households,
    sm.sm_type,
    sm.total_ship_modes,
    sm.distinct_carriers,
    st.s_state,
    st.avg_floor_space,
    st.total_stores,
    wp.wp_type,
    wp.total_web_pages,
    wp.total_links
FROM cp_agg cp
CROSS JOIN cd_agg cd
CROSS JOIN hd_agg hd
INNER JOIN sm_agg sm ON true
INNER JOIN store_agg st ON true
INNER JOIN wp_agg wp ON true
ORDER BY cp.total_pages DESC, sm.total_ship_modes DESC
LIMIT 20

WITH active_sales AS (
    SELECT
        s.s_store_name AS store_name,
        'Active Discount' AS discount_status,
        'Afternoon' AS day_part,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        AVG(p.p_cost) AS avg_promo_cost,
        (SELECT MAX(p2.p_response_target) FROM promotion p2) AS max_response_target,
        s.s_store_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND td.t_hour >= 12
      AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
    GROUP BY s.s_store_name, s.s_store_sk
    HAVING NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN household_demographics hd2 ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND hd2.hd_vehicle_count = -1
    )
),
no_discount_sales AS (
    SELECT
        s.s_store_name AS store_name,
        'No Discount' AS discount_status,
        'Morning' AS day_part,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        AVG(p.p_cost) AS avg_promo_cost,
        (SELECT MAX(p2.p_response_target) FROM promotion p2) AS max_response_target,
        s.s_store_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_discount_active = 'N'
      AND td.t_hour < 12
      AND hd.hd_dep_count <= 2
    GROUP BY s.s_store_name, s.s_store_sk
    HAVING NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN household_demographics hd2 ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND hd2.hd_vehicle_count = -1
    )
)
SELECT
    store_name,
    discount_status,
    day_part,
    total_net_paid,
    sales_cnt,
    avg_promo_cost,
    max_response_target
FROM active_sales
UNION ALL
SELECT
    store_name,
    discount_status,
    day_part,
    total_net_paid,
    sales_cnt,
    avg_promo_cost,
    max_response_target
FROM no_discount_sales
ORDER BY store_name ASC, discount_status DESC
LIMIT 100

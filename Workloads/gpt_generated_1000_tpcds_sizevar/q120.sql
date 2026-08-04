WITH sampled_sales AS (
    SELECT *
    FROM tpcds.store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_promo_sk,
        s1.s_store_id,
        s1.s_store_name,
        cd1.cd_gender,
        cd1.cd_marital_status,
        hd1.hd_buy_potential,
        p1.p_discount_active,
        cd2.cd_education_status        AS cd2_education,
        hd2.hd_vehicle_count          AS hd2_vehicle_cnt,
        p2.p_promo_name                AS p2_name
    FROM sampled_sales ss
    JOIN tpcds.customer_demographics cd1
        ON ss.ss_cdemo_sk = cd1.cd_demo_sk
    JOIN tpcds.customer_demographics cd2
        ON ss.ss_cdemo_sk = cd2.cd_demo_sk
    JOIN tpcds.household_demographics hd1
        ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN tpcds.household_demographics hd2
        ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN tpcds.store s1
        ON ss.ss_store_sk = s1.s_store_sk
    JOIN tpcds.store s2
        ON ss.ss_store_sk = s2.s_store_sk
    JOIN tpcds.promotion p1
        ON ss.ss_promo_sk = p1.p_promo_sk
    JOIN tpcds.promotion p2
        ON ss.ss_promo_sk = p2.p_promo_sk
    WHERE s1.s_gmt_offset = -5.00
      AND hd1.hd_buy_potential = '5001-10000'
      AND cd1.cd_gender = 'F'
),
windowed AS (
    SELECT
        j.*, 
        SUM(j.ss_net_paid) OVER (
            PARTITION BY j.s_store_id 
            ORDER BY j.ss_sold_date_sk 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_net_paid,
        LAG(j.ss_net_paid) OVER (
            PARTITION BY j.s_store_id 
            ORDER BY j.ss_sold_date_sk
        ) AS prev_net_paid
    FROM joined j
),
filtered AS (
    SELECT w.*, ln.store_name_len
    FROM windowed w
    CROSS JOIN LATERAL (
        SELECT length(w.s_store_name) AS store_name_len
    ) ln
    WHERE w.prev_net_paid IS NOT NULL
      AND w.ss_net_paid > w.prev_net_paid
      AND EXISTS (
          SELECT 1
          FROM tpcds.promotion p_check
          WHERE p_check.p_promo_sk = w.ss_promo_sk
            AND p_check.p_discount_active = 'Y'
      )
),
final AS (
    SELECT
        f.s_store_id,
        f.s_store_name,
        f.cd_gender,
        f.hd_buy_potential,
        COUNT(*)                         AS sales_cnt,
        SUM(f.ss_net_paid)               AS total_net_paid,
        MAX(f.running_net_paid)          AS max_running_net_paid,
        MAX(f.store_name_len)            AS store_name_len
    FROM filtered f
    GROUP BY f.s_store_id, f.s_store_name, f.cd_gender, f.hd_buy_potential
)
SELECT *
FROM final
ORDER BY total_net_paid DESC
LIMIT 100

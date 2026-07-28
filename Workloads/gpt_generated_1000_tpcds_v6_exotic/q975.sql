WITH promo_sales_recent AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE p.p_start_date_sk > 2450100
    GROUP BY p.p_promo_id, p.p_promo_name
),
promo_sales_demog AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'College'
    GROUP BY p.p_promo_id, p.p_promo_name
),
unioned AS (
    SELECT * FROM promo_sales_recent
    UNION ALL
    SELECT * FROM promo_sales_demog
)
SELECT
    p_promo_id,
    p_promo_name,
    total_net_paid,
    transaction_count,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_net_paid DESC) AS promo_rank
FROM unioned
ORDER BY total_net_paid DESC
LIMIT 100

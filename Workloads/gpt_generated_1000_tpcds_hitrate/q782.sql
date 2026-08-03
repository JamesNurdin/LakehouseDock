WITH ss_agg AS (
    SELECT
        s.s_store_name AS category_name,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS payment_category
    FROM store_sales ss
    RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'California'
    GROUP BY GROUPING SETS (
        (s.s_store_name, cd.cd_gender),
        (s.s_store_name),
        (cd.cd_gender)
    )
),
cs_agg AS (
    SELECT
        p.p_promo_name AS category_name,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS payment_category
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY GROUPING SETS (
        (p.p_promo_name, cd.cd_gender),
        (p.p_promo_name),
        (cd.cd_gender)
    )
)
SELECT
    category_name,
    gender,
    total_net_paid,
    payment_category
FROM (
    SELECT category_name, gender, total_net_paid, payment_category FROM ss_agg
    UNION ALL
    SELECT category_name, gender, total_net_paid, payment_category FROM cs_agg
) u
WHERE total_net_paid > (
    SELECT AVG(total_net_paid) FROM (
        SELECT total_net_paid FROM ss_agg
        UNION ALL
        SELECT total_net_paid FROM cs_agg
    ) avgs
)
ORDER BY total_net_paid DESC
LIMIT 100

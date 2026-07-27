WITH promo_sales_email AS (
    SELECT
        p.p_promo_id,
        'email' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'high' ELSE 'medium' END AS sales_category
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE p.p_channel_email = 'Y'
      AND c.c_first_sales_date_sk BETWEEN 2450750 AND 2450900
    GROUP BY p.p_promo_id
    HAVING SUM(ss.ss_net_paid) > 5000
),
promo_sales_dmail AS (
    SELECT
        p.p_promo_id,
        'dmail' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'high' ELSE 'medium' END AS sales_category
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE p.p_channel_dmail = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY p.p_promo_id
    HAVING SUM(ss.ss_net_paid) > 5000
)
SELECT *
FROM promo_sales_email
UNION ALL
SELECT *
FROM promo_sales_dmail
ORDER BY total_net_paid DESC
LIMIT 100
